#ifndef __Node__
#define __Node__

class Node {
public:
    //true -> player 0
    //false -> player 1
    bool player0;

    //Important! * -1 when going up
    float payoff;
};
#endif