#ifndef __Trainer__
#define __Trainer__

#include "Template.cuh"
#include "Utils.cuh"

#include<vector>
#include<string>

using std::vector;
using std::string;

constexpr bool gDebug = false;
constexpr auto BLOCKSIZE = 1024;

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

    float* upstreamPayoffs;
};

class TexasHoldemTrainer {
public:
    Template* schablone;
    BlueprintHandler* blueprintHandler;

    vector<double> gpuBenchmarkKernelTimes = { 0.0, 0.0, 0.0 };
    vector<double> gpuBenchmarkCpuTimes = { 0.0, 0.0, 0.0 };
    vector<double> gpuBenchmarkMemcpyTimes = { 0.0 };

    vector<double> cpuBenchmarkCpuTimes = { 0.0, 0.0, 0.0, 0.0, 0.0 };

    TexasHoldemTrainer(string folder, string fileName);
    ~TexasHoldemTrainer();

    void trainCPU(vector<vector<string>>* playerCards);
    void trainGPU(vector<vector<string>>* playerCards, DeviceStructureList* dsl);
    void trainSequentiell(int numIterations, bool useGpu);

    void writeStrategyFromDevice(vector<vector<string>>* playerCards, DeviceStructureList* dsl);
    void loadStrategyToDevice(vector<vector<string>>* playerCards, DeviceStructureList* dsl);
    void setLeafPayoffsGpu(DeviceStructureList* dsl);
    void setReachProbabilitiesAndPoliciesGpu(DeviceStructureList* dsl);
    void setRegretsGpu(DeviceStructureList* dsl);

    void setLeafPayoffsCpu(std::pair<bool, bool> drawPlayerWonPair);
    void loadStrategyCpu(vector<vector<string>>* playerCards);
    void setReachProbabilitiesCpu();
    void setRegretsCpu();
    void writeStrategyCpu(vector<vector<string>>* playerCards);
};

#endif