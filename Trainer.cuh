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

constexpr auto BLOCKSIZE = 512;

struct DeviceStructureList {
    DeviceStructureList* Dself = nullptr;

    int* childrenWorklistPointers = nullptr;
    bool* folded = nullptr;
    int* numStateNodes = nullptr;
    int* numLeafNodes = nullptr;
    int* numChildren = nullptr;
    float* payoff = nullptr;
    bool* player0 = nullptr;
    int* policyPointers = nullptr;
    float* pots = nullptr;
    float* reachProbabilities = nullptr;
    int* worklist = nullptr;

    bool* playerWon = nullptr;
    bool* draw = nullptr;

    int* levelStart = nullptr;
    int* numElements = nullptr;

    float* cumulativeRegrets0;
    float* cumulativeRegrets1;
    float* policy0;
    float* policy1;
};

class TexasHoldemTrainer {
public:
    Template* schablone;
    BlueprintHandler* blueprintHandler;

    TexasHoldemTrainer(std::string path);
    ~TexasHoldemTrainer();

    int trainCPU(vector<vector<string>>* playerCards);
    int trainGPU(vector<vector<string>>* playerCards, DeviceStructureList* dsl);
    int trainSequentiell(int numIterations, bool useGpu);
};

#endif