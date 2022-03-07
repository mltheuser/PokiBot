#include "Template.cuh"
#include "GameState.cuh"
#include "StateNode.cuh"
#include "LeafNode.cuh"

#include <iostream>
#include <algorithm>
#include <cstring>

Template::~Template() {
    for (int round = 0; round < 4; round++) {
        for (int player = 0; player < 2; player++) {
            delete roundInfos.at(round).at(player).blueprintHandler;
        }
        delete roundInfos.at(round).at(0).bucketFunction;
    }

    delete structureList;

}

Template::Template(StructureList* structureList, vector<vector<RoundPlayerInfo>> roundInfos, vector<vector<float>> cumulativeRegrets) {
    this->roundInfos = roundInfos;
    this->structureList = structureList;
    this->cumulativeRegrets = cumulativeRegrets;
}

Template::Template(Template* schablone) {
    this->cumulativeRegrets = schablone->cumulativeRegrets;
    this->roundInfos = schablone->roundInfos;
    this->structureList = schablone->structureList;
}

void Template::createBucketFunctions(std::string path, vector<BucketFunction*>* bucketFunctions) {
    BucketFunction* bucketFunction0 = new BucketFunction(path + "_buckets_" + "0", 0, 2);
    bucketFunctions->push_back(bucketFunction0);
    BucketFunction* bucketFunction1 = new BucketFunction(path + "_buckets_" + "1", 1, 5);
    bucketFunctions->push_back(bucketFunction1);
    BucketFunction* bucketFunction2 = new BucketFunction(path + "_buckets_" + "2", 2, 6);
    bucketFunctions->push_back(bucketFunction2);
    BucketFunction* bucketFunction3 = new BucketFunction(path + "_buckets_" + "3", 3, 7);
    bucketFunctions->push_back(bucketFunction3);
}

struct BuildTreeReturnType Template::buildTree() {
    vector<vector<int>> roundPlayerActionCounts(4, vector<int>(2, 0));

    StateNode* root = new StateNode();
    GameState* gameState = new GameState();

    vector<struct NodeInformation> nodeInformations;
    vector<LeafNode*> leafNodes;
    vector<StateNode*> stateNodes;

    stateNodes.push_back(root);

    struct NodeInformation nodeInformation = { 0, true, gameState };
    nodeInformations.push_back(nodeInformation);

    int index = 0;
    while (index < nodeInformations.size()) {

        struct NodeInformation currentNodeInformation = nodeInformations.at(index);
        int currentNodeIndex = currentNodeInformation.nodeIndex;
        bool currentNodeIsStateNode = currentNodeInformation.isStateNode;
        GameState* currentGameState = currentNodeInformation.gameState;

        index++;
        Node* currentNode;

        if (currentNodeIsStateNode) {
            currentNode = stateNodes.at(currentNodeIndex);

        }
        else {
            currentNode = leafNodes.at(currentNodeIndex);
        }
        currentNode->player0 = currentGameState->player0;
        currentNode->payoff = 0.f;

        if (currentNodeIsStateNode) {
            StateNode* currentStateNode = (StateNode*)currentNode;
            vector<pair<char, float>> actions = currentGameState->getActions();

            roundPlayerActionCounts[currentGameState->round][currentGameState->player0 ? 0 : 1] += actions.size();

            for (pair<char, float> action : actions) {
                HandleActionReturnType handleActionReturnType = currentGameState->handleAction(action);
                int nodeInformationsSize = nodeInformations.size();

                int nodeIndex = 0;
                if (handleActionReturnType.isStateNode) {
                    nodeIndex = stateNodes.size();
                    stateNodes.push_back((StateNode*)handleActionReturnType.node);
                }
                else {
                    nodeIndex = leafNodes.size();
                    leafNodes.push_back(((LeafNode*)handleActionReturnType.node));
                }

                nodeInformations.push_back({ nodeIndex, handleActionReturnType.isStateNode, handleActionReturnType.gameState });
                currentStateNode->children.push_back(nodeInformationsSize);
            }
        }
    }

    int stateNodesSize = stateNodes.size();
    int leafNodesSize = leafNodes.size();
    int worklistSize = stateNodesSize + leafNodesSize;
    auto stateWorklist = vector<StateNode>(stateNodesSize);;
    auto leafWorklist = vector<LeafNode>(leafNodesSize);

    auto worklist = vector<int>(worklistSize);

    for (int i = 0; i < worklistSize; i++) {
        nodeInformation = nodeInformations.at(i);
        int nodeIndex = nodeInformation.nodeIndex;
        if (nodeInformation.isStateNode) {
            stateWorklist[nodeIndex] = *stateNodes.at(nodeIndex);
        }
        else {
            leafWorklist[nodeIndex] = *leafNodes.at(nodeIndex);
            nodeIndex += stateNodesSize;
        }
        worklist[i] = nodeIndex;
    }

    //cleanup GameStates + Nodes
    for (int i = 0; i < worklistSize; i++) {
        delete nodeInformations.at(i).gameState;

        nodeInformation = nodeInformations.at(i);
        int nodeIndex = nodeInformation.nodeIndex;
        if (nodeInformation.isStateNode) {
            delete stateNodes.at(nodeIndex);
        }
        else {
            delete leafNodes.at(nodeIndex);
        }
    }

    struct BuildTreeReturnType buildTreeReturnType = { worklist, worklistSize, stateWorklist, stateNodesSize, leafWorklist, roundPlayerActionCounts };
    return buildTreeReturnType;
}

static vector<vector<RoundPlayerInfo>> buildRoundPlayerInfos(vector<BucketFunction*>* bucketFunctions, vector<vector<int>>* roundPlayerActionCounts) {
    vector<vector<RoundPlayerInfo>> roundPlayerInfos;

    int templatePointers[2] = { 0,0 };

    for (int round = 0; round < 4; round++) {
        vector<RoundPlayerInfo> temp;
        roundPlayerInfos.push_back(temp);
        for (int player = 0; player < 2; player++) {
            BucketFunction* bucketFunction = bucketFunctions->at(round);
            int elementSize = roundPlayerActionCounts->at(round).at(player);
            int startPointTemplate = templatePointers[player];
            templatePointers[player] += elementSize;

            RoundPlayerInfo roundPlayerInfo = RoundPlayerInfo(startPointTemplate, elementSize, bucketFunction, round, player);
            roundPlayerInfos.at(round).push_back(roundPlayerInfo);
        }
    }
    return roundPlayerInfos;
}

static void reduceRoundPlayerActionCounts(vector<vector<int>>* roundPlayerActionCounts, int playerActionCounts[2]) {
    for (int round = 0; round < 4; round++) {
        for (int player = 0; player < 2; player++) {
            playerActionCounts[player] += roundPlayerActionCounts->at(round).at(player);
        }
    }
}

//backwardPass durch worklist
static void worklistBackwardPass(vector<vector<float>>* cumulativeRegrets, vector<int>* worklist, int worklistLength, vector<StateNode>* stateWorklist, int stateWorklistLength, vector<vector<int>>* roundPlayerActionCounts) {
    int playerActionCounts[2] = { 0,0 };
    reduceRoundPlayerActionCounts(roundPlayerActionCounts, playerActionCounts);

    vector<float> player0CumulativeRegrets = vector<float>(playerActionCounts[0]);
    vector<float> player1CumulativeRegrets = vector<float>(playerActionCounts[1]);

    cumulativeRegrets->push_back(player0CumulativeRegrets);
    cumulativeRegrets->push_back(player1CumulativeRegrets);

    int templatePointers[2] = { 0, 0 };

    for (int i = worklistLength - 1; i >= 0; i--) {
        int worklistPointer = worklist->at(i);
        if (worklistPointer < stateWorklistLength) {
            StateNode* stateNode = &stateWorklist->at(worklistPointer);
            stateNode->policyPointer = playerActionCounts[stateNode->player0 ? 0 : 1] - (templatePointers[stateNode->player0 ? 0 : 1] + stateNode->children.size());
            templatePointers[stateNode->player0 ? 0 : 1] += stateNode->children.size();
        }
    }
}

StructureList* treeToLists(struct BuildTreeReturnType* tree) {
    int numStateNodes = tree->stateWorklistLength;
    int numLeafNodes = tree->worklistLength - numStateNodes;
    int numNodes = numStateNodes + numLeafNodes;

    std::vector<int> worklist = tree->worklist;
    auto payoff = vector<float>(numNodes);
    auto player0 = vector<bool>(numNodes);

    auto numChildren = vector<int>(numStateNodes);
    auto policyPointers = vector<int>(numStateNodes);
    auto childrenWorklistPointers = vector<int>(numStateNodes);
    auto reachProbabilities = vector<float>(2 * numStateNodes);

    auto pots = vector<float>(2 * numLeafNodes);
    auto folded = vector<bool>(numLeafNodes);

    for (int i = 0; i < numStateNodes; i++) {
        StateNode* stateNode = &tree->stateWorklist[i];
        // GLOBALE DATEN
        player0[i] = stateNode->player0;
        //TODO stateNodes brauchen keinen payoff mehr, dieser wird eh überschrieben während des Trainings.
        // STATE NODE DATEN
        numChildren[i] = stateNode->children.size();
        policyPointers[i] = stateNode->policyPointer;

        vector<int> children = stateNode->children;
        std::sort(children.begin(), children.end());

        if ((size_t)children.back() - (size_t)children.at(0) != children.size() - (size_t)1) {
            throw "Assertion failed, empty space in children vector found";
        }

        childrenWorklistPointers[i] = children.at(0);

    }

    for (int i = 0; i < numLeafNodes; i++) {
        LeafNode* leafNode = &tree->leafWorklist[i];
        player0[i + numStateNodes] = leafNode->player0;

        pots[i * 2] = leafNode->pot.first;
        pots[(i * 2) + 1] = leafNode->pot.second;

        folded[i] = leafNode->folded;

    }

    //Ebeneninformationen
    vector<int> levelPointers = { 0 };
    int pointer = 0;
    for (int i = 0; i < numStateNodes; i++) {
        int startingLocalMinChildIndex = childrenWorklistPointers[i];
        int localMinChildIndexNumChildren = numChildren[i];
        int localMinChildIndex = numNodes + 1;
        for (int j = 0; j < localMinChildIndexNumChildren; j++) {
            if (worklist[startingLocalMinChildIndex + j] < numStateNodes) {
                localMinChildIndex = std::min(localMinChildIndex, startingLocalMinChildIndex + j);
            }
        }

        if (levelPointers.at(pointer) == i) {
            pointer++;
            levelPointers.push_back(localMinChildIndex);
        }
        else {
            levelPointers.at(pointer) = std::min(localMinChildIndex, levelPointers.at(pointer));
        }
    }

    //TODO wie kann man den Konstruktor direkt mit Parametern aufrufen?
    StructureList* structureList = new StructureList();
    structureList->childrenWorklistPointers = childrenWorklistPointers;
    structureList->folded = folded;
    structureList->levelPointers = levelPointers;
    structureList->numChildren = numChildren;
    structureList->numStateNodes = numStateNodes;
    structureList->numLeafNodes = numLeafNodes;
    structureList->payoff = payoff;
    structureList->player0 = player0;
    structureList->policyPointers = policyPointers;
    structureList->pots = pots;
    structureList->reachProbabilities = reachProbabilities;
    structureList->worklist = worklist;
    return structureList;
}

Template* Template::createDefaultTemplate(std::string path) {
    vector<BucketFunction*> bucketFunctions;
    createBucketFunctions(path, &bucketFunctions);

    struct BuildTreeReturnType tree = buildTree();
    vector<vector<RoundPlayerInfo>> roundPlayerInfos = buildRoundPlayerInfos(&bucketFunctions, &tree.roundPlayerActionCounts);

    vector<vector<float>> cumulativeRegrets;

    worklistBackwardPass(&cumulativeRegrets, &tree.worklist, tree.worklistLength, &tree.stateWorklist, tree.stateWorklistLength, &tree.roundPlayerActionCounts);

    StructureList* listCollection = treeToLists(&tree);

    return new Template(std::move(listCollection), roundPlayerInfos, cumulativeRegrets);
}