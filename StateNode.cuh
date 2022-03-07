#ifndef __StateNode__
#define __StateNode__

#include "Node.cuh"
#include <vector>
#include <iostream>

using std::vector;

class StateNode : public Node {
public:
    int policyPointer;
    vector<int> children;

    StateNode() {
        policyPointer = 0;
        children = vector<int>();
    }

    StateNode& operator=(const StateNode& rhs) { 
        player0 = rhs.player0;
        payoff = rhs.payoff;

        policyPointer = rhs.policyPointer;
        children = rhs.children;
        return *this;
    }
};

#endif