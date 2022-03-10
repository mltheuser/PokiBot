#include "Trainer.cuh"
#include "Template.cuh"
#include "Logger.cuh"
#include "Cards.cuh"
#include "Utils.cuh"

#include "SolverA.cuh"

#include <random>
#include <algorithm>
#include <numeric>
#include <cstring>

#include "cuda_runtime.h"
#include "cuda.h"
#include "cuda_runtime_api.h"
#include "cuda_device_runtime_api.h"
#include "device_functions.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char* file, int line, bool abort = true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

TexasHoldemTrainer::~TexasHoldemTrainer() {
    delete schablone;
}

TexasHoldemTrainer::TexasHoldemTrainer(std::string path) {
    blueprintHandler = nullptr;
    schablone = Template::createDefaultTemplate(path);
}

__global__ void calculatePayoffs(float* dPayoff, float* dPots, bool* dFolded, bool* dPlayer0, int* dNumStateNodes, bool* dPlayerWon, bool* dDraw) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    float* potPointer = dPots + i * 2;
    bool localFolded = dFolded[i];
    bool localPlayer0 = dPlayer0[*dNumStateNodes + i];
    bool currentPlayer = localPlayer0 ? 0 : 1;

    bool localPlayerWon = *dPlayerWon;
    if (localFolded) {
        localPlayerWon = currentPlayer;
    }

    float localPayoff = 0.f;
    if (!*dDraw) {
        localPayoff = potPointer[(currentPlayer + 1) % 2];
    }

    dPayoff[*dNumStateNodes + i] = (localPlayerWon == currentPlayer ? localPayoff : -localPayoff);
}

__global__ void calculateReachProbabilities(float* dReachProbabilities, int* dNumChildren, int* dChildrenWorklistPointers, int* dWorklist, bool* dPlayer0, float* cumulativeRegrets, float* policies, ) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    
    int numChildren = numChildren[i];
    int childrenWorklistPointer = dChildrenWorklistPointers[i];
    int* children = dWorklist + childrenWorklistPointer;
    int currentPlayer = dPlayer0[i] ? 0 : 1;
    int otherPlayer = (currentPlayer + 1) % 2;



    //TODO normalize policies

   /* std::unique_ptr<TrainingInitStruct> trainingInitStruct = initTrainingInitStruct(schablone, i);

    int numChildren = trainingInitStruct->numChildren;
    int* children = trainingInitStruct->children;
    int otherPlayer = trainingInitStruct->otherPlayer;
    int currentPlayer = trainingInitStruct->currentPlayer;
    float* policy = trainingInitStruct->policy;
    float* reachProbabilitiesLocal = trainingInitStruct->reachProbabilitiesLocal;

    for (int j = 0; j < numChildren; j++) {
        if (children[j] < numStateNodes) {
            schablone->structureList->reachProbabilities[2 * children[j] + currentPlayer] = policy[j] * reachProbabilitiesLocal[currentPlayer];
            schablone->structureList->reachProbabilities[2 * children[j] + otherPlayer] = reachProbabilitiesLocal[otherPlayer];
        }
    }
    free(trainingInitStruct->policy);*/
}

//TrainingInitStruct* initTrainingInitStruct(Template* schablone, int i) {
//    int policyPointer = schablone->structureList->policyPointers[i];
//    int numChildren = schablone->structureList->numChildren[i];
//    int childrenWorklistPointer = schablone->structureList->childrenWorklistPointers[i];
//
//    int currentPlayer = schablone->structureList->player0[i] ? 0 : 1;
//    float* cummulativeRegrets = schablone->cumulativeRegrets.at(currentPlayer) + policyPointer;
//    float* policy = (float*)malloc(sizeof(float) * numChildren);
//    std::memcpy(policy, cummulativeRegrets, numChildren * sizeof(float));
//    normalizeStrategy(policy, numChildren);
//    float* reachProbabilitiesLocal = schablone->structureList->reachProbabilities + (i * (size_t)2);
//    int* children = schablone->structureList->worklist + childrenWorklistPointer;
//    int otherPlayer = (currentPlayer + 1) % 2;
//
//    vector<float> reachProbVector;
//    for (int i = 0; i < schablone->structureList->numStateNodes * 2; i++) {
//        reachProbVector.push_back(schablone->structureList->reachProbabilities[i]);
//    }
//
//    TrainingInitStruct trainingInitStruct = TrainingInitStruct();
//
//    trainingInitStruct.policyPointer = policyPointer;
//    trainingInitStruct.numChildren = numChildren;
//    trainingInitStruct.childrenWorklistPointer = childrenWorklistPointer;
//    trainingInitStruct.currentPlayer = currentPlayer;
//    trainingInitStruct.cumulativeRegrets = cummulativeRegrets;
//    trainingInitStruct.policy = policy;
//    trainingInitStruct.reachProbabilitiesLocal = reachProbabilitiesLocal;
//    trainingInitStruct.children = children;
//    trainingInitStruct.otherPlayer = otherPlayer;
//
//    return std::make_unique<TrainingInitStruct>(trainingInitStruct);
//}

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

        util += trainSequentiellIntern(&playerCards);
    }

    saveBucketFunctions();

    Logger::log("Training success");
    return util;
}

void TexasHoldemTrainer::allocateGpuMemory(GpuMemoryPointers* gpuMemoryPointers) {
    int numLeafNodes = schablone->structureList->numLeafNodes;
    int numStateNodes = schablone->structureList->numStateNodes;

    //write
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dPayoff, sizeof(float) * (numLeafNodes + numStateNodes)));
    //TODO
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dPayoff, sizeof(float) * (numLeafNodes + numStateNodes)));

    //read only
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dPots, sizeof(float) * 2 * numLeafNodes));
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dFolded, sizeof(bool) * numLeafNodes));
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dPlayer0, sizeof(bool) * numLeafNodes));
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dNumStateNodes, sizeof(int)));

    //read only, differs in iterations
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dPlayerWon, sizeof(bool)));
    gpuErrchk(cudaMalloc((void**)&gpuMemoryPointers->dDraw, sizeof(bool)));

    //TODO
    float reachProbabilitiesLocal[2] = { 1.f, 1.f };
    gpuErrchk(cudaMemcpy(gpuMemoryPointers->dReachProbabilities, reachProbabilitiesLocal, sizeof(float) * 2, cudaMemcpyHostToDevice));

    gpuErrchk(cudaMemcpy(gpuMemoryPointers->dPots, schablone->structureList->pots, sizeof(float) * 2 * numLeafNodes, cudaMemcpyHostToDevice));
    gpuErrchk(cudaMemcpy(gpuMemoryPointers->dFolded, schablone->structureList->folded, sizeof(bool) * numLeafNodes, cudaMemcpyHostToDevice));
    gpuErrchk(cudaMemcpy(gpuMemoryPointers->dPlayer0, schablone->structureList->player0, sizeof(bool) * numLeafNodes, cudaMemcpyHostToDevice));
    gpuErrchk(cudaMemcpy(gpuMemoryPointers->dNumStateNodes, &numStateNodes, sizeof(int), cudaMemcpyHostToDevice));
}

void TexasHoldemTrainer::cleanUpGpuMemory(GpuMemoryPointers* gpuMemoryPointers) {
    gpuErrchk(cudaFree(gpuMemoryPointers->dPayoff));
    gpuErrchk(cudaFree(gpuMemoryPointers->dPots));
    gpuErrchk(cudaFree(gpuMemoryPointers->dFolded));
    gpuErrchk(cudaFree(gpuMemoryPointers->dPlayer0));
    gpuErrchk(cudaFree(gpuMemoryPointers->dNumStateNodes));
    gpuErrchk(cudaFree(gpuMemoryPointers->dPlayerWon));
    gpuErrchk(cudaFree(gpuMemoryPointers->dDraw));
}

int TexasHoldemTrainer::trainGpu(int numIterations) {
    Logger::log("Training start");

    int util = 0;
    vector<string> cards;
    cards.reserve(52);
    vector<string> player0Cards;
    player0Cards.reserve(7);
    vector<string> player1Cards;
    player1Cards.reserve(7);
    vector<vector<string>> playerCards = { player0Cards, player1Cards };

    GpuMemoryPointers* gpuMemoryPointers = new GpuMemoryPointers();

    allocateGpuMemory(gpuMemoryPointers);

    for (int i = 0; i < numIterations; i++) {
        cards = getCards();
        playerCards.at(0) = { cards.at(0), cards.at(1), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8) };
        playerCards.at(1) = { cards.at(2), cards.at(3), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8) };

        if (i % 1000 == 0) {
            std::cout << "train " << i << std::endl;
        }

        util += trainGpuIntern(&playerCards, gpuMemoryPointers);
    }

    saveBucketFunctions();

    cleanUpGpuMemory(gpuMemoryPointers);

    Logger::log("Training success");
    return util;
}

void TexasHoldemTrainer::saveBucketFunctions() {
    Logger::log("saveBucketFunctions");
    for (int round = 0; round < 4; round++) {
        schablone->roundInfos.at(round).at(0).bucketFunction->saveBucketFunction();
    }
}

int TexasHoldemTrainer::trainGpuIntern(vector<vector<string>>* playerCards, GpuMemoryPointers* gpuMemoryPointers) {

    //a) bestimme gewinner
    int player0Eval = test7(playerCards->at(0));
    int player1Eval = test7(playerCards->at(1));

    bool draw = player0Eval == player1Eval;
    bool playerWon = player0Eval > player1Eval;

    //b) setze payoffs in leafs durch gewinner
    int numLeafNodes = schablone->structureList->numLeafNodes;
    int numStateNodes = schablone->structureList->numStateNodes;

    cudaMemcpy(gpuMemoryPointers->dPlayerWon, &playerWon, sizeof(bool), cudaMemcpyHostToDevice);
    cudaMemcpy(gpuMemoryPointers->dDraw, &draw, sizeof(bool), cudaMemcpyHostToDevice);
    
    dim3 gridSize(1);
    dim3 numLeafNodesBlockSize(numLeafNodes);
    calculatePayoffs<<<gridSize, numLeafNodesBlockSize >>>(gpuMemoryPointers->dPayoff, gpuMemoryPointers->dPots, gpuMemoryPointers->dFolded, gpuMemoryPointers->dPlayer0, gpuMemoryPointers->dNumStateNodes, gpuMemoryPointers->dPlayerWon, gpuMemoryPointers->dDraw);

    gpuErrchk(cudaPeekAtLastError());

    //c_1) prepare strategie laden
    for (int round = 0; round < 4; round++) {
        for (int player = 0; player < 2; player++) {
            RoundPlayerInfo info = schablone->roundInfos.at(round).at(player);
            vector<char> bucket = info.bucketFunction->getBucket(playerCards->at(player));
            int pos = info.bucketFunction->getBucketPosition(bucket);
            int size = info.elementSize;

            size_t max = (info.bucketFunction->bucketList.size()) / (info.bucketFunction->size * 2);
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


    for (int i = 0; i < todo; i++) {
        schablone->structureList->levelPointers.at(i) - schablone->structureList->levelPointers.at(i+1);

        

        calculateReachProbabilities << <1, todo >> > ();
    }
    

    

    //TODO cuda barrier

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

int TexasHoldemTrainer::trainSequentiellIntern(vector<vector<string>>* playerCards) {

    //a) bestimme gewinner
    int player0Eval = test7(playerCards->at(0));
    int player1Eval = test7(playerCards->at(1));

    bool draw = player0Eval == player1Eval;
    bool playerWon = player0Eval > player1Eval;

    //b) setze payoffs in leafs durch gewinner
    int numLeafNodes = schablone->structureList->numLeafNodes;
    int numStateNodes = schablone->structureList->numStateNodes;

    for (int i = 0; i < numLeafNodes; i++) {
        float* potPointer = schablone->structureList->pots + i * 2;
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

            size_t max = (info.bucketFunction->bucketList.size()) / (info.bucketFunction->size * 2);
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
            if (children[j] < numStateNodes) {
                schablone->structureList->reachProbabilities[2 * children[j] + currentPlayer] = policy[j] * reachProbabilitiesLocal[currentPlayer];
                schablone->structureList->reachProbabilities[2 * children[j] + otherPlayer] = reachProbabilitiesLocal[otherPlayer];
            }
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