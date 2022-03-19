#ifndef __Logger__
#define __Logger__

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <chrono>

using std::string;
using std::cout;
using std::endl;

struct PlayResult {
    vector<int> winCounters = { 0, 0 };
    vector<float> payoffCounters = { 0.f, 0.f };
    vector<int> rematchWinCounters = { 0, 0 };
    vector<float> rematchPayoffCounters = { 0.f, 0.f };
};

class Logger {
public:
    static void logToConsole(string logText) {
        cout << logText << endl;
    }

    static void logToFile(string saveText) {
        std::string path = "log.txt";
        std::ofstream write;

        write.open(path.c_str(), std::ios::out | std::ios::binary | std::ios::app);

        write << saveText;
        write.close();
    }

    static void throwRuntimeError(string errorText) {
        logToConsole(errorText);
        logToFile(errorText);
        throw std::runtime_error(errorText);
    }

    static void initBenchmark(string folder, string fileName, std::string device, int blocksize, const std::vector<float> raiseSizes, int trainIterations, int maxIterations, int playIterations) {
        std::string path = folder + "/" + fileName + ".txt";
        std::ofstream write;
        write.open(path.c_str(), std::ios::out | std::ios::app);
        write << "BENCHMARKING started: device = " << device << ", blocksize = " << blocksize << ", raiseSizes = { ";
        for (auto raise : raiseSizes) {
            write << raise << " ";
        }
        write << "} trainIterations = " << trainIterations << ", maxIterations = " << maxIterations << ", playIterations = "<< playIterations << "\n";
        write << "iterations, bucketCount, fileSize, initTime, trainTime, W, L, D, WinPercentageNoDraw, NORMALIZED PAYOFF, REMATCH W, REMATCH L, REMATCH D, REMATCH WinPercentageNoDraw, REMATCH NORMALIZED PAYOFF" << "\n";
        write.close();
    }

    static void logBenchmark(string folder, string fileName, int currentIteration, int playIterations, std::string fileSize, int bucketCount, const std::chrono::system_clock::time_point& initStart, const std::chrono::system_clock::time_point& trainStart, const std::chrono::system_clock::time_point& trainEnd, PlayResult* result) {
        std::string path = folder + "/" + fileName + ".txt";
        std::ofstream write;

        auto initTime = std::chrono::duration_cast<std::chrono::milliseconds>(trainStart - initStart).count();
        auto trainTime = std::chrono::duration_cast<std::chrono::milliseconds>(trainEnd - trainStart).count();

        int player0Wins = result->winCounters.at(0);
        int player1Wins = result->winCounters.at(1);
        int draws = playIterations - player0Wins - player1Wins;
        int iterationsWithWinner = playIterations - draws;
        float player0Payoffs = result->payoffCounters.at(0);
        float player1Payoffs = result->payoffCounters.at(1);

        int rematchPlayer0Wins = result->rematchWinCounters.at(1);
        int rematchPlayer1Wins = result->rematchWinCounters.at(0);
        int rematchDraws = playIterations - rematchPlayer0Wins - rematchPlayer1Wins;
        int rematchIterationsWithWinner = playIterations - rematchDraws;
        float rematchPlayer0Payoffs = result->rematchPayoffCounters.at(1);
        float rematchPlayer1Payoffs = result->rematchPayoffCounters.at(0);

        float winPercentagePlayer0 = (static_cast<float>(player0Wins) / static_cast<float>(playIterations));
        float loosePercentagePlayer0 = (static_cast<float>(player1Wins) / static_cast<float>(playIterations));
        float drawPercentage = (static_cast<float>(draws) / static_cast<float>(playIterations));
        float winPercentagePlayer0NoDraws = (static_cast<float>(player0Wins) / static_cast<float>(iterationsWithWinner));

        vector<float> normalizedPayoffCounters = { player0Payoffs / playIterations, player1Payoffs / playIterations };

        float rematchWinPercentagePlayer0 = (static_cast<float>(rematchPlayer0Wins) / static_cast<float>(playIterations));
        float rematchLoosePercentagePlayer0 = (static_cast<float>(rematchPlayer1Wins) / static_cast<float>(playIterations));
        float rematchDrawPercentage = (static_cast<float>(rematchDraws) / static_cast<float>(playIterations));
        float rematchWinPercentagePlayer0NoDraws = (static_cast<float>(rematchPlayer0Wins) / static_cast<float>(rematchIterationsWithWinner));

        vector<float> rematchNormalizedPayoffCounters = { rematchPlayer0Payoffs / playIterations, rematchPlayer1Payoffs / playIterations };

        write.open(path.c_str(), std::ios::out | std::ios::app);

        write << currentIteration << "," << bucketCount << "," << fileSize << "," << initTime << "," << trainTime << "," << winPercentagePlayer0 << "," << loosePercentagePlayer0 << "," << drawPercentage << "," <<  winPercentagePlayer0NoDraws << ", " << normalizedPayoffCounters.at(0) << "," << rematchWinPercentagePlayer0 << "," << rematchLoosePercentagePlayer0 << "," << rematchDrawPercentage << "," << rematchWinPercentagePlayer0NoDraws << ", " << rematchNormalizedPayoffCounters.at(0) << "\n";

        write.close();
    }

    static void logIteration(int iteration) {
        std::ostringstream log;

        log << "Iteration: " << iteration;

        logToConsole(log.str());
    }

    static void logStart(string device, int blocksize, int iterations) {
        std::ostringstream log;

        log << "device: "  << device << " blocksize: " << blocksize << " Iterations: " << iterations << endl;

        logToConsole(log.str());
    }

    static void logInit(const std::chrono::system_clock::time_point& initStart, const std::chrono::system_clock::time_point& initEnd) {
        std::ostringstream log;

        auto initTime = std::chrono::duration_cast<std::chrono::milliseconds>(initEnd - initStart).count();

        log << "Schablone erstellt in: " << initTime << " ms" << endl;

        logToConsole(log.str());
        logToFile(log.str());
    }

    static void logPlay(PlayResult* result, int iterations) {
        std::ostringstream log;

        int player0Wins = result->winCounters.at(0);
        int player1Wins = result->winCounters.at(1);
        int draws = iterations - player0Wins - player1Wins;
        int iterationsWithWinner = iterations - draws;
        float player0Payoffs = result->payoffCounters.at(0);
        float player1Payoffs = result->payoffCounters.at(1);

        int rematchPlayer0Wins = result->rematchWinCounters.at(1);
        int rematchPlayer1Wins = result->rematchWinCounters.at(0);
        int rematchDraws = iterations - rematchPlayer0Wins - rematchPlayer1Wins;
        int rematchIterationsWithWinner = iterations - rematchDraws;
        float rematchPlayer0Payoffs = result->rematchPayoffCounters.at(1);
        float rematchPlayer1Payoffs = result->rematchPayoffCounters.at(0);

        float winPercentagePlayer0 = (static_cast<float>(player0Wins) / static_cast<float>(iterations));
        float winPercentagePlayer1 = (static_cast<float>(player1Wins) / static_cast<float>(iterations));
        float drawPercentage = (static_cast<float>(draws) / static_cast<float>(iterations));
        float winPercentagePlayer0NoDraws = (static_cast<float>(player0Wins) / static_cast<float>(iterationsWithWinner));

        vector<float> normalizedPayoffCounters = { player0Payoffs / iterations, player1Payoffs / iterations };

        float rematchWinPercentagePlayer0 = (static_cast<float>(rematchPlayer0Wins) / static_cast<float>(iterations));
        float rematchWinPercentagePlayer1 = (static_cast<float>(rematchPlayer1Wins) / static_cast<float>(iterations));
        float rematchDrawPercentage = (static_cast<float>(rematchDraws) / static_cast<float>(iterations));
        float rematchWinPercentagePlayer0NoDraws = (static_cast<float>(rematchPlayer0Wins) / static_cast<float>(rematchIterationsWithWinner));

        vector<float> rematchNormalizedPayoffCounters = { rematchPlayer0Payoffs / iterations, rematchPlayer1Payoffs / iterations };


        log << "W/L/D: "  << winPercentagePlayer0 << "/" << winPercentagePlayer1 << "/" << drawPercentage << endl;

        log << "PAYOFF: " << player0Payoffs << "( NORMALIZED: " << normalizedPayoffCounters.at(0) << " )" << endl;

        log << "\n" << "REMATCH(Player 0 playing in second position) : \n";

        log << "W/L/D: " << rematchWinPercentagePlayer0 << "/" << rematchWinPercentagePlayer1 << "/" << rematchDrawPercentage << endl;

        log << "PAYOFF: " << rematchPlayer0Payoffs << "( NORMALIZED: " << rematchNormalizedPayoffCounters.at(0) << " )" << endl;

        logToConsole(log.str());
        logToFile(log.str());
    }

    static void logTraining(const std::chrono::system_clock::time_point& trainStart, const std::chrono::system_clock::time_point& trainFinish, int iterations) {
        std::ostringstream log;

        auto trainTime = std::chrono::duration_cast<std::chrono::milliseconds>(trainFinish - trainStart).count();
        auto trainTimeSeconds = std::chrono::duration_cast<std::chrono::seconds>(trainFinish - trainStart).count();
        auto timePerIteration = trainTime / static_cast<float>(iterations);

        log << iterations << " Iterationen trainiert in: " << trainTime << " ms [" << trainTimeSeconds << "s, "  << timePerIteration << " ms/iteration]" << endl;
        
        logToConsole(log.str());
        logToFile(log.str());
    }
};

#endif