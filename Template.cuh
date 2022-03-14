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

typedef struct {
    vector<int> childrenWorklistPointers;
    vector<bool> folded;
    vector<int> levelPointers;
    int numStateNodes = 0;
    int numLeafNodes = 0;
    vector<int> numChildren;
    vector<float> payoff;
    vector<bool> player0;
    vector<int> policyPointers;
    vector<float> pots;
    vector<float> reachProbabilities;
    vector<int> worklist;
} StructureList;

struct BuildTreeReturnType {
    vector<int> worklist;
    int worklistLength;
    vector<StateNode> stateWorklist;
    int stateWorklistLength;
    vector<LeafNode> leafWorklist;
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
    vector<vector<float>> cumulativeRegrets;

    ~Template();
    Template(StructureList* structureList, vector<vector<RoundPlayerInfo>> roundInfos, vector<vector<float>> cumulativeRegrets);
    Template(Template* schablone);

    static void createBucketFunctions(std::string path, vector<BucketFunction*>* bucketFunctions);
    static struct BuildTreeReturnType buildTree();
    static Template* createDefaultTemplate(std::string path);

};
#endif