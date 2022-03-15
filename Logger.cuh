#ifndef __Logger__
#define __Logger__

#include <iostream>
#include <fstream>
#include <sstream>

using std::string;
using std::cout;
using std::endl;

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
        throw std::runtime_error("errorText");
    }

    static void logBenchmark(int deviceOption, int iterations, int bucketCount, const std::chrono::system_clock::time_point& initStart, const std::chrono::system_clock::time_point& trainStart, const std::chrono::system_clock::time_point& trainEnd, float winsPlayer0, float payoffPlayer0) {
        std::string path = "benchmark.txt";
        std::ofstream write;

        auto initTime = std::chrono::duration_cast<std::chrono::milliseconds>(trainStart - initStart).count();
        auto trainTime = std::chrono::duration_cast<std::chrono::milliseconds>(trainEnd - trainStart).count();

        write.open(path.c_str(), std::ios::out | std::ios::binary | std::ios::app);

        //TODO filesize

        char* deviceOptionChar = (char*)&deviceOption;
        write.write(deviceOptionChar, sizeof(int));

        char* iterationsChar = (char*)&iterations;
        write.write(iterationsChar, sizeof(int));

        char* bucketCountChar = (char*)&bucketCount;
        write.write(bucketCountChar, sizeof(int));

        char* initTimeChar = (char*)&initTime;
        write.write(initTimeChar, sizeof(int));

        char* trainTimeChar = (char*)&trainTime;
        write.write(trainTimeChar, sizeof(int));

        //TODO umrechnen in winrate
        char* winrateChar = (char*)&winsPlayer0;
        write.write(winrateChar, sizeof(float));

        //TODO normalisieren?
        char* payoffChar = (char*)&payoffPlayer0;
        write.write(payoffChar, sizeof(float));

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

    static void logPlay(int player0Wins, int player1Wins, float player0Payoffs, float player1Payoffs, int iterations) {
        std::ostringstream log;

        float winPercentage = (static_cast<float>(player0Wins) / static_cast<float>(player0Wins + player1Wins));
        vector<float> normalizedPayoffCounters = { player0Payoffs / iterations, player1Payoffs / iterations };

        log << "Wins P0: " << player0Wins << " || Wins P1: " << player1Wins << endl;
        log << "P0 hat eine Winrate von: " << winPercentage << " auf " << iterations << " Iterationen" << endl;
        log << "Payoff P0: " << player0Payoffs << "(Normalisiert: " << normalizedPayoffCounters.at(0) << ") Payoff P1: " << player1Wins << "(Normalisiert: " << normalizedPayoffCounters.at(1) << ")" << endl;

        logToConsole(log.str());
        logToFile(log.str());
    }

    static void logTraining(const std::chrono::system_clock::time_point& trainStart, const std::chrono::system_clock::time_point& trainFinish, int iterations) {
        std::ostringstream log;

        auto trainTime = std::chrono::duration_cast<std::chrono::milliseconds>(trainFinish - trainStart).count();
        auto timePerIteration = trainTime / static_cast<float>(iterations);

        log << "Trainiert in: " << trainTime << " ms (" << timePerIteration << " ms pro Iteration)" << endl;
        
        logToConsole(log.str());
        logToFile(log.str());
    }
};

#endif