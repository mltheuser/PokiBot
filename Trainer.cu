#include "Trainer.cuh"
#include "Template.cuh"
#include "Logger.cuh"
#include "Cards.cuh"
#include "Utils.cuh"

#include <random>
#include <algorithm>
#include <numeric>
#include <cstring>

TexasHoldemTrainer::~TexasHoldemTrainer() {
    delete schablone;
}

TexasHoldemTrainer::TexasHoldemTrainer(std::string path) {
    blueprintHandler = nullptr;
    schablone = Template::createDefaultTemplate(path);
}

int TexasHoldemTrainer::trainSequentiell(int numIterations) {
    Logger::log("Training start");

    int util = 0;
    vector<string> cards;
    cards.reserve(52);
    vector<string> player0Cards;
    player0Cards.reserve(7);
    vector<string> player1Cards;
    player1Cards.reserve(7);
    vector<vector<string>> playerCards = { player0Cards, player1Cards };

    for (int i = 0; i < numIterations; i++) {
        cards = getCards();
        playerCards.at(0) = { cards.at(0), cards.at(1), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8) };
        playerCards.at(1) = { cards.at(2), cards.at(3), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8) };

        if (i % 1000 == 0) {
            std::cout << "train " << i << std::endl;
        }

        util += train(&playerCards);
    }

    std::cout << "saveBucketFunctions" << std::endl;
    for (int round = 0; round < 4; round++) {
        schablone->roundInfos.at(round).at(0).bucketFunction->saveBucketFunction();
    }

    Logger::log("Training success");
    return util;
}

int TexasHoldemTrainer::train(vector<vector<string>>* playerCards) {

    //a) bestimme gewinner
    int player0Eval = 1;
    int player1Eval = 0;

    bool draw = player0Eval == player1Eval;
    bool playerWon = player0Eval > player1Eval;

    //b) setze payoffs in leafs durch gewinner
    int numLeafNodes = schablone->structureList->numLeafNodes;
    int numStateNodes = schablone->structureList->numStateNodes;

    for (int i = 0; i < numLeafNodes; i++) {
        float* potPointer = schablone->structureList->pots + i * (size_t)2;
        bool folded = schablone->structureList->folded[i];
        bool player0 = schablone->structureList->player0[numStateNodes + i];
        bool currentPlayer = player0 ? 0 : 1;

        bool localePlayerWon = playerWon;
        if (folded) {
            localePlayerWon = currentPlayer;
        }

        float payoff = 0.f;
        if (!draw) {
            payoff = potPointer[(currentPlayer + 1) % 2];
        }

        schablone->structureList->payoff[numStateNodes + i] = (localePlayerWon == currentPlayer ? payoff : -payoff);
    }

    //c_1) prepare strategie laden
    for (int round = 0; round < 4; round++) {
        for (int player = 0; player < 2; player++) {
            RoundPlayerInfo info = schablone->roundInfos.at(round).at(player);
            vector<char> bucket = info.bucketFunction->getBucket(playerCards->at(player));
            int pos = info.bucketFunction->getBucketPosition(bucket);
            int size = info.elementSize;

            int max = (info.bucketFunction->bucketList.size()) / (info.bucketFunction->size * 2);
            bool newBucket = pos >= max;

            if (newBucket) {
                info.bucketFunction->bucketList.insert(info.bucketFunction->bucketList.end(), bucket.begin(), bucket.end());
                float* zeroArray = new float[size] {0.f};
                info.blueprintHandler->writePolicies(pos, size * sizeof(float), zeroArray);
                delete[](zeroArray);

                int otherPlayer = (player + 1) % 2;
                RoundPlayerInfo otherInfo = schablone->roundInfos.at(round).at(otherPlayer);
                int otherSize = otherInfo.elementSize;
                float* otherZeroArray = new float[otherSize] {0.f};
                otherInfo.blueprintHandler->writePolicies(pos, otherSize * sizeof(float), otherZeroArray);
                delete[](otherZeroArray);
            }
            float* reads = info.blueprintHandler->readPolicies(pos, size * sizeof(float));
            std::memcpy(schablone->cumulativeRegrets.at(player) + info.startPointTemplate, reads, size * sizeof(float));
            delete[] reads;
        }
    }

    //c_2) forwardpass: setze reach probabilities
    schablone->structureList->reachProbabilities[0] = 1.f;
    schablone->structureList->reachProbabilities[1] = 1.f;

    for (int i = 0; i < numStateNodes; i++) {
        std::unique_ptr<TrainingInitStruct> trainingInitStruct = initTrainingInitStruct(schablone, i);

        int numChildren = trainingInitStruct->numChildren;
        int* children = trainingInitStruct->children;
        int otherPlayer = trainingInitStruct->otherPlayer;
        int currentPlayer = trainingInitStruct->currentPlayer;
        float* policy = trainingInitStruct->policy;
        float* reachProbabilitiesLocal = trainingInitStruct->reachProbabilitiesLocal;

        for (int j = 0; j < numChildren; j++) {
            schablone->structureList->reachProbabilities[2 * children[j] + currentPlayer] = policy[j] * reachProbabilitiesLocal[currentPlayer];
            schablone->structureList->reachProbabilities[2 * children[j] + otherPlayer] = reachProbabilitiesLocal[otherPlayer];
        }
        free(trainingInitStruct->policy);
    }

    //d_1) backwardpass: setze regrets
    for (int i = numStateNodes - 1; i >= 0; i--) {
        std::unique_ptr<TrainingInitStruct> trainingInitStruct = initTrainingInitStruct(schablone, i);

        int* children = trainingInitStruct->children;
        int numChildren = trainingInitStruct->numChildren;

        vector<float> upstreamPayoffs;
        upstreamPayoffs.reserve(numChildren);

        for (int j = 0; j < numChildren; j++) {
            upstreamPayoffs.push_back(-1 * schablone->structureList->payoff[children[j]]);
        }

        float* policy = trainingInitStruct->policy;

        float* cumulativeRegrets = trainingInitStruct->cumulativeRegrets;

        float nodeUtility = std::inner_product(policy, policy + numChildren, upstreamPayoffs.begin(), 0.f);
        schablone->structureList->payoff[i] = nodeUtility;

        float* reachProbabilitiesLocal = trainingInitStruct->reachProbabilitiesLocal;
        int currentPlayer = trainingInitStruct->currentPlayer;
        int otherPlayer = trainingInitStruct->otherPlayer;

        float counterValue = reachProbabilitiesLocal[currentPlayer] * nodeUtility;

        vector<float> counterActionValues;
        counterActionValues.reserve(numChildren);

        for (int j = 0; j < numChildren; j++) {
            counterActionValues.push_back(1 * upstreamPayoffs[j]);
        }

        vector<float> counterRegrets;
        counterRegrets.reserve(numChildren);

        for (int j = 0; j < numChildren; j++) {
            counterRegrets.push_back(reachProbabilitiesLocal[otherPlayer] * (counterActionValues[j] - counterValue));

            cumulativeRegrets[j] = cumulativeRegrets[j] + std::max(0.f, counterRegrets[j]);
        }
        free(trainingInitStruct->policy);
    }

    //d_2) postpare strategie zurückschreiben
    for (int round = 0; round < 4; round++) {
        for (int player = 0; player < 2; player++) {
            RoundPlayerInfo info = schablone->roundInfos.at(round).at(player);
            int pos = info.bucketFunction->getBucketPosition(info.bucketFunction->getBucket(playerCards->at(player)));

            int size = info.elementSize;

            info.blueprintHandler->writePolicies(pos, size * sizeof(float), schablone->cumulativeRegrets.at(player) + info.startPointTemplate);
        }
    }

    //util?
    return 0;
}