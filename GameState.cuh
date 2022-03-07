#ifndef __GameState__
#define __GameState__

#include "Node.cuh"

#include <vector>
#include <string>
#include <map>
#include <tuple>

using std::vector;
using std::string;
using std::map;
using std::pair;

class GameState {
public:
    bool player0;
    //permitted values: 'C', 'F', 'R'. In case of getActions or smth. lexicographical order!
    vector<char> history;
    //permitted values: 0, 1, 2, 3
    int round;
    pair<float, float> pot;

    GameState();
    GameState(const GameState& gameState);
    vector<pair<char, float>> getActions();
    struct HandleActionReturnType handleAction(pair<char, float> action);
    void adjustPot(pair<char, float> action);
};
#endif