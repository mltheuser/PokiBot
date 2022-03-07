#include "SolverA.cuh"
#include "evaluator.cuh"
#include "card.cuh"

int test7(std::vector<std::string> cards) {
    phevaluator::Card hole1 = phevaluator::Card(cards.at(0));
    phevaluator::Card hole2 = phevaluator::Card(cards.at(1));
    phevaluator::Card board1 = phevaluator::Card(cards.at(2));
    phevaluator::Card board2 = phevaluator::Card(cards.at(3));
    phevaluator::Card board3 = phevaluator::Card(cards.at(4));
    phevaluator::Card board4 = phevaluator::Card(cards.at(5));
    phevaluator::Card board5 = phevaluator::Card(cards.at(6));

    return EvaluateCards(hole1, hole2, board1, board2, board3, board4, board5).value();
}

int test(string holeCard, string boardCard1, string boardCard2, string boardCard3, string boardCard4) {
    
    phevaluator::Card hole1 = phevaluator::Card(holeCard);
    phevaluator::Card board1 = phevaluator::Card(boardCard1);
    phevaluator::Card board2 = phevaluator::Card(boardCard2);
    phevaluator::Card board3 = phevaluator::Card(boardCard3);
    phevaluator::Card board4 = phevaluator::Card(boardCard4);

    return EvaluateCards(hole1, board1, board2, board3, board4).value();
}






