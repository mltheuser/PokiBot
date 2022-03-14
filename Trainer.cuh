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

class TexasHoldemTrainer {
public:
    Template* schablone;
    BlueprintHandler* blueprintHandler;

    TexasHoldemTrainer(std::string path);
    ~TexasHoldemTrainer();

    int train(vector<vector<string>>* playerCards);
    int trainSequentiell(int numIterations);
    float cfr(GameState gameState, vector<float> reachProbabilities);
    void sortCards(vector<string>& cards);
    void buildTree();
};

#endif