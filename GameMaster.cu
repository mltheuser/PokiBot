#include "GameMaster.cuh"
#include "Utils.cuh"
#include "SolverA.cuh"


GameMaster::GameMaster(std::string path) {
    this->path = path;
}

PlayResult GameMaster::playBlueprintVersusRandom(int iterations) {
    Template* schablone = Template::createDefaultTemplate(path);

    BlueprintAkteur* blueprintAkteur = new BlueprintAkteur(path);
    RandomAkteur* randomAkteur = new RandomAkteur(path);
    vector<Akteur*> akteure = { blueprintAkteur, randomAkteur };

    PlayResult playResult = PlayResult();

    
    for (int i = 0; i < iterations; i++) {
        //if (i % 1000 == 0) Logger::logIteration(i);

        vector<std::string> cards = getCards();

        std::pair<int, float> result = play(schablone, cards, akteure);
        int winner = result.first;
        float payoff = result.second;
        
        if (winner < 0) {
            continue;
        }
        else {
            playResult.winCounters.at(winner)++;
            playResult.payoffCounters.at(winner) += payoff;
            playResult.payoffCounters.at((winner + 1) % 2) -= payoff;
        }
    }
    
    delete blueprintAkteur;
    delete randomAkteur;
    delete schablone;

    return playResult;
}

std::pair<int, float> GameMaster::play(Template* schablone, vector<std::string> cards, vector<Akteur*> akteure) {

    InformationSet* informationSet = new InformationSet();
    informationSet->actionHistory = vector<pair<char, float>>();
    informationSet->currentRoundActionHistory = vector<pair<char, float>>();
    informationSet->player = 0;
    informationSet->round = 0;
    informationSet->playerCardsVisible = mapCardsToVisibility(cards, 0, 0);

    while (true) {
        pair<char, float> action = akteure.at(informationSet->player)->act(informationSet);

        if (action.first == 'f') {
            int winner = (informationSet->player + 1) % 2;
            std::pair<int, GameState*> result = getCurrentNode(schablone, informationSet->actionHistory);
            GameState* currentGameState = result.second;
            float payoff = winner == 0 ? currentGameState->pot.second : currentGameState->pot.first;
            delete currentGameState;
            return std::pair<int, float>(winner, payoff);
        }
        else if (roundEnd(informationSet->currentRoundActionHistory, action)) {
            if (informationSet->round == 3) {
                vector<vector<string>> playerCards = { {cards.at(0), cards.at(1), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8)}, {cards.at(2), cards.at(3), cards.at(4), cards.at(5), cards.at(6), cards.at(7), cards.at(8)} };
                int player0Eval = test7(playerCards.at(0));
                int player1Eval = test7(playerCards.at(1));

                bool draw = player0Eval == player1Eval;
                bool playerWon = player0Eval > player1Eval;

                int winner = draw ? -1 : playerWon ? 0 : 1;
                std::pair<int, GameState*> result = getCurrentNode(schablone, informationSet->actionHistory);
                GameState* currentGameState = result.second;
                float payoff = 0.f;
                if (!draw) {
                    payoff = winner == 0 ? currentGameState->pot.second : currentGameState->pot.first;
                    delete currentGameState;
                }

                return std::pair<int, float>(winner, payoff);
            }
            else {
                informationSet->round++;
                informationSet->player = 0;
                informationSet->actionHistory.push_back(action);
                informationSet->currentRoundActionHistory = vector<pair<char, float>>();
            }
        }
        else {
            informationSet->player = (informationSet->player + 1) % 2;
            informationSet->actionHistory.push_back(action);
            informationSet->currentRoundActionHistory.push_back(action);
        }
        informationSet->playerCardsVisible = mapCardsToVisibility(cards, informationSet->player, informationSet->round);
    }

    delete informationSet;
}

void GameMaster::playBlueprintVersusBlueprint(int iterations) {
    Template* schablone = Template::createDefaultTemplate(path);

    BlueprintAkteur* blueprintAkteur1 = new BlueprintAkteur(path);
    BlueprintAkteur* blueprintAkteur2 = new BlueprintAkteur(path);
    vector<Akteur*> akteure = { blueprintAkteur1, blueprintAkteur2 };

    vector<std::string> cards = getCards();

    play(schablone, cards, akteure);

    delete blueprintAkteur1;
    delete blueprintAkteur2;
    delete schablone;
}