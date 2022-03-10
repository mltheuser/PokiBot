#ifndef __Trainer__
#define __Trainer__

#include "BucketFunction.cuh"
#include "Template.cuh"
#include "GameState.cuh"
#include "Utils.cuh"

#include <map>
#include <vector>
#include <string>
#include <numeric>
#include <random>
#include <iostream>
#include <mutex>
#include <list>

using std::vector;
using std::string;
using std::map;

typedef struct {
    float* dPayoff = nullptr;
    //TODO
    float* dReachProbabilities = nullptr;

    float* dPots = nullptr;
    bool* dFolded = nullptr;
    bool* dPlayer0 = nullptr;
    int* dNumStateNodes = nullptr;
    bool* dPlayerWon = nullptr;
    bool* dDraw = nullptr;
} GpuMemoryPointers;

class TexasHoldemTrainer {
public:
    Template* schablone;
    BlueprintHandler* blueprintHandler;

    TexasHoldemTrainer(std::string path);
    ~TexasHoldemTrainer();

    int trainSequentiellIntern(vector<vector<string>>* playerCards);
    int trainSequentiell(int numIterations);
    int trainGpuIntern(vector<vector<string>>* playerCards, GpuMemoryPointers* gpuMemoryPointers);
    int trainGpu(int numIterations);
    void saveBucketFunctions();
    float cfr(GameState gameState, vector<float> reachProbabilities);
    void sortCards(vector<string>& cards);
    void buildTree();
    void allocateGpuMemory(GpuMemoryPointers* gpuMemoryPointers);
    void cleanUpGpuMemory(GpuMemoryPointers* gpuMemoryPointers);
};

#endif