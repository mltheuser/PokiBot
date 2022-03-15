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

TexasHoldemTrainer::~TexasHoldemTrainer() {
    delete schablone;
}

TexasHoldemTrainer::TexasHoldemTrainer(std::string path) {
    blueprintHandler = nullptr;
    schablone = Template::createDefaultTemplate(path);
}


#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char* file, int line, bool abort = true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}


DeviceStructureList* prepareDevice(Template* schablone) {
    int numStateNodes = schablone->structureList->numStateNodes;
    int numLeafNodes = schablone->structureList->numLeafNodes;
    int worklistSize = numStateNodes + numLeafNodes;

    DeviceStructureList* dsl = new DeviceStructureList();
    size_t size = 0;

    size = sizeof(int) * numStateNodes;
    gpuErrchk(cudaMalloc((void**)&dsl->childrenWorklistPointers, size));
    gpuErrchk(cudaMemcpy(dsl->childrenWorklistPointers, schablone->structureList->childrenWorklistPointers, size, cudaMemcpyHostToDevice));

    size = sizeof(bool) * numLeafNodes;
    gpuErrchk(cudaMalloc((void**)&dsl->folded, size));
    gpuErrchk(cudaMemcpy(dsl->folded, schablone->structureList->folded, size, cudaMemcpyHostToDevice));

    size = sizeof(int) * numStateNodes;
    gpuErrchk(cudaMalloc((void**)&dsl->numChildren, size));
    gpuErrchk(cudaMemcpy(dsl->numChildren, schablone->structureList->numChildren, size, cudaMemcpyHostToDevice));

    size = sizeof(int);
    gpuErrchk(cudaMalloc((void**)&dsl->numLeafNodes, size));
    gpuErrchk(cudaMemcpy(dsl->numLeafNodes, &schablone->structureList->numLeafNodes, size, cudaMemcpyHostToDevice));

    size = sizeof(int);
    gpuErrchk(cudaMalloc((void**)&dsl->numStateNodes, size));
    gpuErrchk(cudaMemcpy(dsl->numStateNodes, &schablone->structureList->numStateNodes, size, cudaMemcpyHostToDevice));

    size = sizeof(float) * worklistSize;
    gpuErrchk(cudaMalloc((void**)&dsl->payoff, size));
    
    size = sizeof(bool) * worklistSize;
    gpuErrchk(cudaMalloc((void**)&dsl->player0, size));
    gpuErrchk(cudaMemcpy(dsl->player0, schablone->structureList->player0, size, cudaMemcpyHostToDevice));

    size = sizeof(int) * numStateNodes;
    gpuErrchk(cudaMalloc((void**)&dsl->policyPointers, size));
    gpuErrchk(cudaMemcpy(dsl->policyPointers, schablone->structureList->policyPointers, size, cudaMemcpyHostToDevice));

    size = sizeof(float) * numLeafNodes * 2;
    gpuErrchk(cudaMalloc((void**)&dsl->pots, size));
    gpuErrchk(cudaMemcpy(dsl->pots, schablone->structureList->pots, size, cudaMemcpyHostToDevice));

    size = sizeof(float) * numStateNodes * 2;
    gpuErrchk(cudaMalloc((void**)&dsl->reachProbabilities, size));

    size = sizeof(int) * worklistSize;
    gpuErrchk(cudaMalloc((void**)&dsl->worklist, size));
    gpuErrchk(cudaMemcpy(dsl->worklist, schablone->structureList->worklist, size, cudaMemcpyHostToDevice));

    size = sizeof(bool);
    gpuErrchk(cudaMalloc((void**)&dsl->playerWon, size));

    size = sizeof(bool);
    gpuErrchk(cudaMalloc((void**)&dsl->draw, size));

    size = sizeof(int);
    gpuErrchk(cudaMalloc((void**)&dsl->levelStart, size));

    size = sizeof(int);
    gpuErrchk(cudaMalloc((void**)&dsl->numElements, size));

    size = schablone->roundInfos.at(3).at(0).startPointTemplate + schablone->roundInfos.at(3).at(0).elementSize;
    size = size * sizeof(float);
    gpuErrchk(cudaMalloc((void**)&dsl->cumulativeRegrets0, size));
    gpuErrchk(cudaMalloc((void**)&dsl->policy0, size));

    size = schablone->roundInfos.at(3).at(1).startPointTemplate + schablone->roundInfos.at(3).at(1).elementSize;
    size = size * sizeof(float);
    gpuErrchk(cudaMalloc((void**)&dsl->cumulativeRegrets1, size));
    gpuErrchk(cudaMalloc((void**)&dsl->policy1, size));

    size = sizeof(DeviceStructureList);
    gpuErrchk(cudaMalloc((void**)&dsl->Dself, size));
    gpuErrchk(cudaMemcpy(dsl->Dself, dsl, size, cudaMemcpyHostToDevice));

    return dsl;
}


void freeDeviceStructureList(DeviceStructureList* dsl) {
    gpuErrchk(cudaFree(dsl->childrenWorklistPointers));
    gpuErrchk(cudaFree(dsl->folded));
    gpuErrchk(cudaFree(dsl->numChildren));
    gpuErrchk(cudaFree(dsl->numLeafNodes));
    gpuErrchk(cudaFree(dsl->numStateNodes));
    gpuErrchk(cudaFree(dsl->payoff));
    gpuErrchk(cudaFree(dsl->player0));
    gpuErrchk(cudaFree(dsl->policyPointers));
    gpuErrchk(cudaFree(dsl->pots));
    gpuErrchk(cudaFree(dsl->reachProbabilities));
    gpuErrchk(cudaFree(dsl->worklist));

    gpuErrchk(cudaFree(dsl->playerWon));
    gpuErrchk(cudaFree(dsl->draw));

    gpuErrchk(cudaFree(dsl->levelStart));
    gpuErrchk(cudaFree(dsl->numElements));

    gpuErrchk(cudaFree(dsl->cumulativeRegrets0));
    gpuErrchk(cudaFree(dsl->cumulativeRegrets1));
    gpuErrchk(cudaFree(dsl->policy0));
    gpuErrchk(cudaFree(dsl->policy1));

    gpuErrchk(cudaFree(dsl->Dself));
    free(dsl);
}


void TexasHoldemTrainer::trainSequentiell(int numIterations, bool useGpu) {
    Logger::logToConsole("Training start");
    vector<string> cards;
    cards.reserve(52);
    vector<string> player0Cards;
    player0Cards.reserve(7);
    vector<string> player1Cards;
    player1Cards.reserve(7);
    vector<vector<string>> playerCards = { player0Cards, player1Cards };

    DeviceStructureList* deviceStructureListPtr = nullptr;
    if (useGpu) {
        deviceStructureListPtr = prepareDevice(this->schablone);
    }

    for (int i = 0; i < numIterations; i++) {
        cards = getCards();
        playerCards.at(0) = { cards.at(0), cards.at(1), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8) };
        playerCards.at(1) = { cards.at(2), cards.at(3), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8) };

        if (i % 1000 == 0) {
            Logger::logIteration(i);
        }
        
        if (useGpu) {
            trainGPU(&playerCards, deviceStructureListPtr);
        }
        else {
            trainCPU(&playerCards);
        }
    }

    if (useGpu) {
        freeDeviceStructureList(deviceStructureListPtr);
    }

    for (int round = 0; round < 4; round++) {
        schablone->roundInfos.at(round).at(0).bucketFunction->saveBucketFunction();
    }
}

void TexasHoldemTrainer::trainCPU(vector<vector<string>>* playerCards) {

    //a) bestimme gewinner
    int player0Eval = test7(playerCards->at(0));
    int player1Eval = test7(playerCards->at(1));

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
        TrainingInitStruct* trainingInitStruct = initTrainingInitStruct(schablone, i);

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
        free(trainingInitStruct);
    }

    //d_1) backwardpass: setze regrets
    for (int i = numStateNodes - 1; i >= 0; i--) {
        TrainingInitStruct* trainingInitStruct = initTrainingInitStruct(schablone, i);

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
        free(trainingInitStruct);
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
}

__global__ void setLeafPayoffs(DeviceStructureList* dsl) {

    int id = blockIdx.x * blockDim.x + threadIdx.x;

    if (id >= *dsl->numElements) {
        return;
    }

    float* potPointer = dsl->pots + id * 2;
    bool localFolded = dsl->folded[id];
    bool localPlayer0 = dsl->player0[*dsl->numStateNodes + id];
    bool currentPlayer = localPlayer0 ? 0 : 1;

    bool localPlayerWon = *dsl->playerWon;
    if (localFolded) {
        localPlayerWon = currentPlayer;
    }

    float localPayoff = 0.f;
    if (!*dsl->draw) {
        localPayoff = potPointer[1 - currentPlayer];
    }

    dsl->payoff[*dsl->numStateNodes + id] = (localPlayerWon == currentPlayer ? localPayoff : -localPayoff);
}

__device__ TrainingInitStruct* getInitStructGPU(DeviceStructureList* dsl, int i) {
    int policyPointer = dsl->policyPointers[i];
    int numChildren = dsl->numChildren[i];
    int childrenWorklistPointer = dsl->childrenWorklistPointers[i];

    int currentPlayer = dsl->player0[i] ? 0 : 1;
    float* cummulativeRegrets = dsl->player0[i] ? dsl->cumulativeRegrets0 + policyPointer : dsl->cumulativeRegrets1 + policyPointer;

    float* policy = dsl->player0[i] ? dsl->policy0 + policyPointer : dsl->policy1 + policyPointer;

    float* reachProbabilitiesLocal = dsl->reachProbabilities + (i * 2);
    int* children = dsl->worklist + childrenWorklistPointer;
    int otherPlayer = 1 - currentPlayer;

    auto trainingInitStruct = new TrainingInitStruct();

    trainingInitStruct->policyPointer = policyPointer;
    trainingInitStruct->numChildren = numChildren;
    trainingInitStruct->childrenWorklistPointer = childrenWorklistPointer;
    trainingInitStruct->currentPlayer = currentPlayer;
    trainingInitStruct->cumulativeRegrets = cummulativeRegrets;
    trainingInitStruct->policy = policy;
    trainingInitStruct->reachProbabilitiesLocal = reachProbabilitiesLocal;
    trainingInitStruct->children = children;
    trainingInitStruct->otherPlayer = otherPlayer;

    return trainingInitStruct;
}

__global__ void setReachProbsAndPolicy(DeviceStructureList* dsl) {

    int id = blockIdx.x * blockDim.x + threadIdx.x;

    if (id >= *dsl->numElements) {
        return;
    }

    id += *dsl->levelStart;

    auto tis = getInitStructGPU(dsl, id);

    int numChildren = tis->numChildren;
    float* policy = tis->policy;
    int* children = tis->children;
    int currentPlayer = tis->currentPlayer;
    int otherPlayer = tis->otherPlayer;
    float* reachProbabilitiesLocal = tis->reachProbabilitiesLocal;

    for (int i = 0; i < numChildren; i++) {
        policy[i] = fmaxf(policy[i], 0.f);
    }

    float arraySum = 0;
    for (int i = 0; i < numChildren; i++) {
        arraySum += policy[i];
    }

    if (arraySum > 0) {
        for (int i = 0; i < numChildren; i++) {
            policy[i] /= arraySum;
        }
    }
    else {
        for (int i = 0; i < numChildren; i++) {
            policy[i] = 1.f / numChildren;
        }
    }

    for (int j = 0; j < numChildren; j++) {
        if (children[j] < *dsl->numStateNodes) {
            dsl->reachProbabilities[2 * children[j] + currentPlayer] = policy[j] * reachProbabilitiesLocal[currentPlayer];
            dsl->reachProbabilities[2 * children[j] + otherPlayer] = reachProbabilitiesLocal[otherPlayer];
        }
    }

    free(tis);
}

__global__ void setRegrets(DeviceStructureList* dsl) {
    
    int id = blockIdx.x * blockDim.x + threadIdx.x;

    if (id >= *dsl->numElements) {
        return;
    }

    id += *dsl->levelStart;

    TrainingInitStruct* trainingInitStruct = getInitStructGPU(dsl, id);

    int* children = trainingInitStruct->children;
    int numChildren = trainingInitStruct->numChildren;

    float* upstreamPayoffs = new float[numChildren];

    float nodeUtility = 0.f;
    for (int j = 0; j < numChildren; j++) {

        upstreamPayoffs[j] = -dsl->payoff[children[j]];

        nodeUtility += trainingInitStruct->policy[j] * upstreamPayoffs[j];

    }

    dsl->payoff[id] = nodeUtility;

    float* reachProbabilitiesLocal = trainingInitStruct->reachProbabilitiesLocal;
    int currentPlayer = trainingInitStruct->currentPlayer;
    int otherPlayer = trainingInitStruct->otherPlayer;

    float counterValue = reachProbabilitiesLocal[currentPlayer] * nodeUtility;

    float* cumulativeRegrets = trainingInitStruct->cumulativeRegrets;
    for (int j = 0; j < numChildren; j++) {
        float counterActionValue = upstreamPayoffs[j];
        cumulativeRegrets[j] = cumulativeRegrets[j] + fmaxf(0.f, reachProbabilitiesLocal[otherPlayer] * (counterActionValue - counterValue));
    }

    free(upstreamPayoffs);

    free(trainingInitStruct);
}

struct GetIndexReturnType {
    int levelStart = 0;
    int numElements = 0;
};

GetIndexReturnType getIndexList(Template* schablone, int levelIndex) {
    auto levelPointers = schablone->structureList->levelPointers;
    int levelStart = schablone->structureList->worklist[levelPointers.at(levelIndex)];
    int numElements;
    if (levelIndex == levelPointers.size() - 1) {
        numElements = schablone->structureList->numStateNodes - levelStart;
    }
    else {
        numElements = schablone->structureList->worklist[levelPointers.at(levelIndex + 1)] - levelStart;
    }

    return GetIndexReturnType { levelStart, numElements};
}

void TexasHoldemTrainer::trainGPU(vector<vector<string>>* playerCards, DeviceStructureList* dsl) {

    //a) bestimme gewinner
    int player0Eval = test7(playerCards->at(0));
    int player1Eval = test7(playerCards->at(1));

    bool draw = player0Eval == player1Eval;
    bool playerWon = player0Eval > player1Eval;
    gpuErrchk(cudaMemcpy(dsl->draw, &draw, sizeof(bool), cudaMemcpyHostToDevice));
    gpuErrchk(cudaMemcpy(dsl->playerWon, &playerWon, sizeof(bool), cudaMemcpyHostToDevice));

    //b) setze payoffs in leafs durch gewinner
    int numLeafNodes = schablone->structureList->numLeafNodes;

    int N = numLeafNodes;
    cudaMemcpy(dsl->numElements, &N, sizeof(int), cudaMemcpyHostToDevice);
    int blockSize = BLOCKSIZE;
    int numBlocks = (N + blockSize - 1) / blockSize;
    setLeafPayoffs << < numBlocks, blockSize >> > (dsl->Dself);
    gpuErrchk(cudaPeekAtLastError());
    gpuErrchk(cudaDeviceSynchronize());

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

            size = size * sizeof(float);
            if (player == 0) {
                gpuErrchk(cudaMemcpy(dsl->cumulativeRegrets0 + info.startPointTemplate, reads, size, cudaMemcpyHostToDevice));
                gpuErrchk(cudaMemcpy(dsl->policy0 + info.startPointTemplate, reads, size, cudaMemcpyHostToDevice));
            }
            else {
                gpuErrchk(cudaMemcpy(dsl->cumulativeRegrets1 + info.startPointTemplate, reads, size, cudaMemcpyHostToDevice));
                gpuErrchk(cudaMemcpy(dsl->policy1 + info.startPointTemplate, reads, size, cudaMemcpyHostToDevice));
            }

            delete[] reads;
        }
    }

    cudaDeviceSynchronize();

    //c_2) forwardpass: setze reach probabilities
    schablone->structureList->reachProbabilities[0] = 1.f;
    schablone->structureList->reachProbabilities[1] = 1.f;

    gpuErrchk(cudaMemcpy(dsl->reachProbabilities, schablone->structureList->reachProbabilities, sizeof(float) * 2, cudaMemcpyHostToDevice));

    auto levelPointers = schablone->structureList->levelPointers;
    for (int i = 0; i < levelPointers.size(); i++) {
        GetIndexReturnType indexListData = getIndexList(schablone, i);
        
        int numElements = indexListData.numElements;
        cudaMemcpy(dsl->levelStart, &indexListData.levelStart, sizeof(int), cudaMemcpyHostToDevice);

        int N = numElements;
        cudaMemcpy(dsl->numElements, &N, sizeof(int), cudaMemcpyHostToDevice);
        int blockSize = BLOCKSIZE;
        int numBlocks = (N + blockSize - 1) / blockSize;
        setReachProbsAndPolicy << < numBlocks, blockSize >> > (dsl->Dself);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        cudaDeviceSynchronize();
    }

    //d_1) backwardpass: setze regrets
    for (int i = levelPointers.size() - 1; i >= 0; i--) {
        GetIndexReturnType indexListData = getIndexList(schablone, i);

        int numElements = indexListData.numElements;
        cudaMemcpy(dsl->levelStart, &indexListData.levelStart, sizeof(int), cudaMemcpyHostToDevice);

        int N = numElements;
        cudaMemcpy(dsl->numElements, &N, sizeof(int), cudaMemcpyHostToDevice);
        int blockSize = BLOCKSIZE;
        int numBlocks = (N + blockSize - 1) / blockSize;
        setRegrets << < numBlocks, blockSize >> > (dsl->Dself);
        gpuErrchk(cudaPeekAtLastError());
        gpuErrchk(cudaDeviceSynchronize());

        cudaDeviceSynchronize();
    }

    //d_2) postpare strategie zurückschreiben

    int dArrSize = schablone->roundInfos.at(3).at(0).startPointTemplate + schablone->roundInfos.at(3).at(0).elementSize;
    dArrSize = dArrSize * sizeof(float);
    cudaMemcpy(schablone->cumulativeRegrets.at(0), dsl->cumulativeRegrets0, dArrSize, cudaMemcpyDeviceToHost);
    dArrSize = schablone->roundInfos.at(3).at(1).startPointTemplate + schablone->roundInfos.at(3).at(1).elementSize;
    dArrSize = dArrSize * sizeof(float);
    cudaMemcpy(schablone->cumulativeRegrets.at(1), dsl->cumulativeRegrets1, dArrSize, cudaMemcpyDeviceToHost);

    for (int round = 0; round < 4; round++) {
        for (int player = 0; player < 2; player++) {
            RoundPlayerInfo info = schablone->roundInfos.at(round).at(player);
            int pos = info.bucketFunction->getBucketPosition(info.bucketFunction->getBucket(playerCards->at(player)));

            int size = info.elementSize;

            info.blueprintHandler->writePolicies(pos, size * sizeof(float), schablone->cumulativeRegrets.at(player) + info.startPointTemplate);
        }
    }
}