#ifndef __LeafNode__
#define __LeafNode__

#include "Node.cuh"
#include <tuple>

class LeafNode : public Node {
public:
    bool folded;
    //ein bet ist immer ein vielfaches vom SmallBlind!
    std::pair<float, float> pot;

    LeafNode() {
        folded = false;
        pot = std::pair<float, float>();
    }

    LeafNode& operator=(const LeafNode& rhs) {
        player0 = rhs.player0;
        payoff = rhs.payoff;
        folded = rhs.folded;
        pot = rhs.pot;
        return *this;
    }
};

#endif