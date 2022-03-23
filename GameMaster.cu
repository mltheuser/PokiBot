#include "GameMaster.cuh"
#include "Utils.cuh"
#include "SolverA.cuh"


GameMaster::GameMaster(std::string folder, std::string fileName) {
    this->folder = folder;
    this->fileName = fileName;
}

PlayResult* GameMaster::playBlueprintVersusManual() {
    return nullptr;
}

PlayResult* GameMaster::playBlueprintVersusRandom(int iterations) {
    Template* schablone = Template::createDefaultTemplate(folder, fileName);

    BlueprintAkteur* blueprintAkteur = new BlueprintAkteur(folder, fileName);
    RandomAkteur* randomAkteur = new RandomAkteur(folder, fileName);

    vector<Akteur*> akteure = { blueprintAkteur, randomAkteur };
    vector<Akteur*> rematchAkteure = { randomAkteur, blueprintAkteur };


    PlayResult* playResult = new PlayResult();

    Logger::logToConsole("Play start");
    for (int i = 0; i < iterations; i++) {
        if (i % 10000 == 0) Logger::logIteration(i);

        vector<std::string> cards = getCards();

        std::pair<int, float> result = play(schablone, cards, akteure);
        int winner = result.first;
        float payoff = result.second;
        std::pair<int, float> rematchResult = play(schablone, cards, rematchAkteure);
        int rematchWinner = rematchResult.first;
        float rematchPayoff = rematchResult.second;

        
        if (winner < 0) {
            continue;
        }
        else {
            playResult->winCounters.at(winner)++;
            playResult->payoffCounters.at(winner) += payoff;
            playResult->payoffCounters.at((winner + 1) % 2) -= payoff;
        }

        if (rematchWinner < 0) {
            continue;
        }
        else {
            playResult->rematchWinCounters.at(rematchWinner)++;
            playResult->rematchPayoffCounters.at(rematchWinner) += rematchPayoff;
            playResult->rematchPayoffCounters.at((rematchWinner + 1) % 2) -= rematchPayoff;
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
            float payoff = winner == 0 ? result.second->pot.second : result.second->pot.first;
            delete result.second;
            delete informationSet;
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
                float payoff = 0.f;
                if (!draw) {
                    payoff = winner == 0 ? result.second->pot.second : result.second->pot.first;    
                }

                delete informationSet;
                delete result.second;
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

PlayResult* GameMaster::playBlueprintVersusBlueprint(int iterations, string comparisonBlueprintName) {
    Template* schablone = Template::createDefaultTemplate(folder, fileName);

    BlueprintAkteur* blueprintAkteur = new BlueprintAkteur(folder, fileName);
    BlueprintAkteur* comparisonBlueprintAkteur = new BlueprintAkteur(folder, comparisonBlueprintName + "_" + fileName);

    vector<Akteur*> akteure = { blueprintAkteur, comparisonBlueprintAkteur };
    vector<Akteur*> rematchAkteure = { comparisonBlueprintAkteur, blueprintAkteur };

    PlayResult* playResult = new PlayResult();

    for (int i = 0; i < iterations; i++) {
        //if (i % 1000 == 0) Logger::logIteration(i);

        vector<std::string> cards = getCards();

        std::pair<int, float> result = play(schablone, cards, akteure);
        std::pair<int, float> rematchResult = play(schablone, cards, rematchAkteure);
        int winner = result.first;
        float payoff = result.second;
        int rematchWinner = rematchResult.first;
        float rematchPayoff = rematchResult.second;

        if (winner < 0) {
            continue;
        }
        else {
            playResult->winCounters.at(winner)++;
            playResult->payoffCounters.at(winner) += payoff;
            playResult->payoffCounters.at((winner + 1) % 2) -= payoff;
        }

        if (rematchWinner < 0) {
            continue;
        }
        else {
            playResult->rematchWinCounters.at(rematchWinner)++;
            playResult->rematchPayoffCounters.at(rematchWinner) += rematchPayoff;
            playResult->rematchPayoffCounters.at((rematchWinner + 1) % 2) -= rematchPayoff;
        }
    }

    delete blueprintAkteur;
    delete comparisonBlueprintAkteur;
    delete schablone;

    return playResult;
}