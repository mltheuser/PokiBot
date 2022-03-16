#ifndef __main__
#define __main__

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#include "Trainer.cuh"
#include "GameMaster.cuh"
#include "Logger.cuh"

#include <cstdio>
#include <vector>
#include <time.h>
#include <string>

using std::cout;
using std::endl;
using std::cin;
using std::vector;

vector<string> CONSOLE_OPTIONS = { "clear", "train", "play", "benchmark", "exit" };
vector<string> DEVICE_OPTIONS = { "cpu", "gpu" };
vector<string> PLAY_OPTIONS = { "vsRandom" };
string GET_ITERATIONS = "Input number of iterations: ";
string GET_WRONG_INPUT = "Falsche Eingabe ... zurück zur Hauptauswahl";

void benchmark() {
    std::chrono::system_clock::time_point initStart, trainStart, trainFinish;
    int iterations = 1000;
    //gpu
    Logger::logStart(DEVICE_OPTIONS.at(1), BLOCKSIZE, iterations);

    initStart = std::chrono::system_clock::now();
    TexasHoldemTrainer trainer = TexasHoldemTrainer("blueprint");
    trainStart = std::chrono::system_clock::now();
    Logger::logInit(initStart, trainStart);

    trainer.trainSequentiell(iterations, true);
    trainFinish = std::chrono::system_clock::now();
    Logger::logTraining(trainStart, trainFinish, 1000);

    GameMaster gameMaster = GameMaster("blueprint");
    PlayResult result = gameMaster.playBlueprintVersusRandom(iterations);

    Logger::logPlay(result.winCounters.at(0), result.winCounters.at(1), result.payoffCounters.at(0), result.payoffCounters.at(1), iterations);

    trainer.schablone->roundInfos.at(3).at(0).bucketFunction->loadBucketFunction();
    size_t bucketListSize = trainer.schablone->roundInfos.at(3).at(0).bucketFunction->bucketList.size();
    size_t bucketSize = trainer.schablone->roundInfos.at(3).at(0).bucketFunction->size * 2;
    size_t bucketCount = bucketListSize / bucketSize;

    Logger::logBenchmark(1, iterations, bucketCount, initStart, trainStart, trainFinish, result.winCounters.at(0), result.payoffCounters.at(0));
}

void clearFiles() {
    using std::remove;

    remove("blueprint_buckets_0");
    remove("blueprint_buckets_1");
    remove("blueprint_buckets_2");
    remove("blueprint_buckets_3");

    remove("blueprint00");
    remove("blueprint01");
    remove("blueprint10");
    remove("blueprint11");
    remove("blueprint20");
    remove("blueprint21");
    remove("blueprint30");
    remove("blueprint31");
}

std::string getOptions(std::vector<string> options) {
    std::ostringstream optionsString;
    for (int i = 0; i < options.size(); i++) {
        optionsString << options.at(i) << " (" << i << ")" << (i == options.size()-1 ? ": " : ", ");
    }
    return optionsString.str();
}

void clear() {
    clearFiles();
    cout << "cleared successfully" << endl;
   /* int deviceOption;

    cout << "device: cpu(0), gpu(1), all(2)";
    cin >> deviceOption;
    if (deviceOption == '0') {
        clearFiles("cpu");
    }
    else if (deviceOption == '1') {
        clearFiles("gpu");
    }
    else if (deviceOption == '2') {
        clearFiles("cpu");
        clearFiles("gpu");
    }
    else {
        std::cout << "deletion aborted" << std::endl;
    }*/
}

void play() {
    int playOption, iterations;

    cout << GET_ITERATIONS;
    cin >> iterations;
    GameMaster gameMaster = GameMaster("blueprint");
    PlayResult result = gameMaster.playBlueprintVersusRandom(iterations);

    Logger::logPlay(result.winCounters.at(0), result.winCounters.at(1), result.payoffCounters.at(0), result.payoffCounters.at(1), iterations);
}

void train() {
    int deviceOption, iterations;
    std::chrono::system_clock::time_point initStart, trainStart, trainFinish;

    cout << getOptions(DEVICE_OPTIONS);
    cin >> deviceOption;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    cout << GET_ITERATIONS;
    cin >> iterations;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    Logger::logStart(DEVICE_OPTIONS.at(deviceOption), BLOCKSIZE, iterations);

    initStart = std::chrono::system_clock::now();
    TexasHoldemTrainer trainer = TexasHoldemTrainer("blueprint");
    trainStart = std::chrono::system_clock::now();
    Logger::logInit(initStart, trainStart);

    trainer.trainSequentiell(iterations, deviceOption == 1);
    trainFinish = std::chrono::system_clock::now();
    Logger::logTraining(trainStart, trainFinish, iterations);

    if (gDebug) {
        for (int i = 0; i < 3; i++) {
            Logger::logToConsole(std::to_string(trainer.elapsedKernelTimes.at(i) /= iterations));
        }
    }

}

int main() {
    srand(0);

    int consoleOption;

    while (true) {
        cout << getOptions(CONSOLE_OPTIONS);
        cin >> consoleOption;

        if (!cin) {
            cout << GET_WRONG_INPUT << endl;
            std::cin.clear();
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            continue;
        }

        switch (consoleOption) {
        case 0:
            clear();
            break;
        case 1:
            train();
            break;
        case 2:
            play();
            break;
        case 3:
            benchmark();
            break;
        case 4:
            return;
        }
    }
}
#endif