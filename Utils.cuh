#ifndef __Utils__
#define __Utils__

#include <memory>
#include <random>

#include "Template.cuh"
#include "BucketFunction.cuh"

typedef struct trainingInitStruct {
    int policyPointer;
    int numChildren;
    int childrenWorklistPointer;
    int currentPlayer;
    std::vector<float> policy;
    std::vector<float> cumulativeRegrets;
    std::vector<float> reachProbabilitiesLocal;
    std::vector<int> children;
    int otherPlayer;
} TrainingInitStruct;

void normalizeStrategy(std::vector<float> policy, int size);
std::unique_ptr<TrainingInitStruct> initTrainingInitStruct(Template* schablone, int i);
bool roundEnd(vector<char> history, char action);
bool roundEnd(vector<pair<char, float>> history, pair<char, float> action);
vector<string> getCards();
vector<string> mapCardsToVisibility(vector<string> cards, int player, int round);
std::pair<int, GameState*> getCurrentNode(Template* schablone, std::vector<std::pair<char, float>> actionHistory);

#endif