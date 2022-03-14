#include "Utils.cuh"
#include "Cards.cuh"
#include <cstring>
#include "RaiseBuckets.cuh"

// std::default_random_engine engine = std::default_random_engine();
std::default_random_engine engine;

void normalizeStrategy(float* policy, int size) {
    for (int i = 0; i < size; i++) {
        policy[i] = std::max(policy[i], 0.f);
    }

    float arraySum = 0;

    for (int i = 0; i < size; i++) {
        arraySum += policy[i];
    }

    if (arraySum > 0) {
        for (int i = 0; i < size; i++) {
            policy[i] /= arraySum;
        }
    }
    else {
        for (int i = 0; i < size; i++) {
            policy[i] = 1.f / size;
        }
    }
}

TrainingInitStruct* initTrainingInitStruct(Template* schablone, int i) {
    int policyPointer = schablone->structureList->policyPointers[i];
    int numChildren = schablone->structureList->numChildren[i];
    int childrenWorklistPointer = schablone->structureList->childrenWorklistPointers[i];

    int currentPlayer = schablone->structureList->player0[i] ? 0 : 1;
    float* cummulativeRegrets = schablone->cumulativeRegrets.at(currentPlayer) + policyPointer;
    float* policy = (float*)malloc(sizeof(float) * numChildren);
    std::memcpy(policy, cummulativeRegrets, numChildren * sizeof(float));
    normalizeStrategy(policy, numChildren);
    float* reachProbabilitiesLocal = schablone->structureList->reachProbabilities + (i * (size_t)2);
    int* children = schablone->structureList->worklist + childrenWorklistPointer;
    int otherPlayer = (currentPlayer + 1) % 2;

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

bool roundEnd(vector<char> history, char action) {
    return !history.empty() && ((history.back() == 'c' || history.back() == 'r') && action == 'c');
}

bool roundEnd(vector<pair<char, float>> history, pair<char, float> action) {
    return !history.empty() && ((history.back().first == 'c' || history.back().first == 'r') && action.first == 'c');
}

vector<string> getCards() {
    vector<std::string> cards = Cards::getCards();
    std::shuffle(cards.begin(), cards.end(), engine);

    return cards;
}

vector<string> mapCardsToVisibility(vector<string> cards, int player, int round) {
    vector<string> visibleCards;

    visibleCards.push_back(player == 0 ? cards.at(0) : cards.at(2));
    visibleCards.push_back(player == 0 ? cards.at(1) : cards.at(3));

    if (round >= 1) {
        visibleCards.push_back(cards.at(4));
        visibleCards.push_back(cards.at(5));
        visibleCards.push_back(cards.at(6));
        if (round >= 2) {
            visibleCards.push_back(cards.at(7));
            if (round >= 3) {
                visibleCards.push_back(cards.at(8));
            }
        }
    }

    return visibleCards;
}

std::pair<int, GameState*> getCurrentNode(Template* schablone, std::vector<std::pair<char, float>> actionHistory) {

    // init with root
    int currentNode = *(schablone->structureList->worklist);
    GameState* currentGameState = new GameState();

    for (int i = 0; i < actionHistory.size(); i++) {

        pair<char, float> currentAction = actionHistory.at(i).first == 'r' ? pair<char, float>('r', getRaise(actionHistory.at(i).second)) : actionHistory.at(i);

        vector<pair<char, float>> possibleActions = currentGameState->getActions();

        std::vector<pair<char, float>>::iterator it = std::find(possibleActions.begin(), possibleActions.end(), currentAction);

        int index = it - possibleActions.begin();

        int currentNodeIndex = *(schablone->structureList->childrenWorklistPointers + currentNode) + index;

        currentNode = schablone->structureList->worklist[currentNodeIndex];

        currentGameState = currentGameState->handleAction(currentAction).gameState;

    }

    return pair<int, GameState*>(currentNode, currentGameState);

}