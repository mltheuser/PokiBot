#ifndef __Cards__
#define __Cards__

#include <vector>
#include <string>

class Cards {
public:
    static const std::vector<std::string> getCards() {
        std::vector<char> suits = { 'c', 's', 'h', 'd' };
        std::vector<char> ranks = { '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };
        std::vector<std::string> cards;
        for (char suit : suits) {
            for (char rank : ranks) {
                cards.push_back(std::string() + rank + suit);
            }
        }
        return cards;
    }
};
#endif