#ifndef __Template__
#define __Template__

#include "LeafNode.cuh"
#include "StateNode.cuh"
#include "RoundPlayerInfo.cuh"
#include "GameState.cuh"

#include <tuple>
#include <vector>

using std::vector;
using std::pair;

struct StructureList {
    int* childrenWorklistPointers = nullptr;
    bool* folded = nullptr;
    vector<int> levelPointers;
    int numStateNodes = 0;
    int numLeafNodes = 0;
    int* numChildren = nullptr;
    float* payoff = nullptr;
    bool* player0 = nullptr;
    int* policyPointers = nullptr;
    float* pots = nullptr;
    float* reachProbabilities = nullptr;
    int* worklist = nullptr;
};

struct BuildTreeReturnType {
    int* worklist;
    int worklistLength;
    StateNode* stateWorklist;
    int stateWorklistLength;
    LeafNode* leafWorklist;
    vector<vector<int>> roundPlayerActionCounts;
};

struct NodeInformation {
    int nodeIndex;
    bool isStateNode;
    GameState* gameState;
};

struct HandleActionReturnType {
    Node* node;
    bool isStateNode;
    GameState* gameState;
};

class Template {
public:
    //4 x 2
    vector<vector<RoundPlayerInfo>> roundInfos;
    StructureList* structureList;
    vector<float*> cumulativeRegrets;

    ~Template();
    Template(StructureList* structureList, vector<vector<RoundPlayerInfo>> roundInfos, vector<float*> cumulativeRegrets);
    Template(Template* schablone);

    static void createBucketFunctions(std::string folder, std::string fileName, vector<BucketFunction*>* bucketFunctions);
    static struct BuildTreeReturnType buildTree();
    static Template* createDefaultTemplate(std::string folder, std::string fileName);

};
#endif