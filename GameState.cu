#include "GameState.cuh"
#include "StateNode.cuh"
#include "LeafNode.cuh"
#include "Template.cuh"
#include "Utils.cuh"
#include "RaiseBuckets.cuh"

#include <algorithm>
#include <iostream>

GameState::GameState() {
    player0 = true;
    history = {};
    round = 0;
    pot = { 0,0 };
}

GameState::GameState(const GameState& gameState) {
    player0 = gameState.player0;
    history = gameState.history;
    round = gameState.round;
    pot = gameState.pot;
}

vector<pair<char, float>> GameState::getActions() {
    vector<pair<char, float>> actions{ pair<char,float>('c',0.f) };

    if ((history.size() != 0 && history.back() == 'r')) actions.push_back(pair<char, float>('f', 0.f));
    if (history.size() < 2) {
        vector<pair<char, float>> raiseSizes = getRaises();
        for (pair<char, float> raiseSize : raiseSizes) {
            actions.push_back(raiseSize);
        }
    }

    return actions;
}

/**
 * Spieler ist der alte(?)
 */
void GameState::adjustPot(pair<char, float> action) {
    if (action.first == 'f') return;

    if (action.first == 'c') {
        player0 ? pot.first = pot.second : pot.second = pot.first;
        return;
    }

    if (action.first == 'r') {
        player0 ? pot.first = pot.second += action.second : pot.second = pot.first + action.second;
        return;
    }
}

/**
 * action + gamestate -> gibt Knoten und neuen GameState
 * Knoten kann State/LEaf
 * Leaf -> pot und durch isFold
 * State -> -
 */
struct HandleActionReturnType GameState::handleAction(pair<char, float> action) {

    GameState thisGameState = *this;
    GameState* gameState = new GameState(thisGameState);

    gameState->adjustPot(action);

    if (action.first == 'f') {
        gameState->player0 = !gameState->player0;
        LeafNode* node = new LeafNode();
        node->pot = gameState->pot;
        node->folded = true;
        return HandleActionReturnType { node, false, gameState };

    }
    else if (roundEnd(history, action.first)) {
        if (round == 3) {
            gameState->player0 = !gameState->player0;
            LeafNode* node = new LeafNode();
            node->pot = gameState->pot;
            node->folded = false;
            return HandleActionReturnType { node, false, gameState };

        }
        else {
            gameState->player0 = true;
            gameState->history = {};
            gameState->round++;
            StateNode* node = new StateNode();
            return HandleActionReturnType { node, true, gameState };
        }

    }
    else {
        gameState->player0 = !gameState->player0;
        gameState->history.push_back(action.first);
        StateNode* node = new StateNode();
        return HandleActionReturnType { node, true, gameState };
    }
}