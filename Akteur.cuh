#ifndef __Akteur__
#define __Akteur__

#include <tuple>
#include <vector>
#include <string>

typedef struct {
    std::vector<std::string> playerCardsVisible;
    int player;
    int round;
    std::vector<std::pair<char, float>> actionHistory;
    std::vector<std::pair<char, float>> currentRoundActionHistory;
} InformationSet;

class Akteur {
public:
    virtual std::pair<char, float> act(InformationSet* informationSet) = 0;
};
#endif