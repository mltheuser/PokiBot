#ifndef __main__
#define __main__

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#include "Trainer.cuh"
#include "GameMaster.cuh"
#include "Logger.cuh"
#include "RaiseBuckets.cuh"

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
string FOLDER = "outputs";

void clearFiles(std::string folder, std::string filePrefix) {
    using std::remove;

    remove((folder + "/" + filePrefix + "_buckets_0").c_str());
    remove((folder + "/" + filePrefix + "_buckets_1").c_str());
    remove((folder + "/" + filePrefix + "_buckets_2").c_str());
    remove((folder + "/" + filePrefix + "_buckets_3").c_str());

    remove((folder + "/" + filePrefix + "00").c_str());
    remove((folder + "/" + filePrefix + "00").c_str());

    remove((folder + "/" + filePrefix + "00").c_str());
    remove((folder + "/" + filePrefix + "00").c_str());

    remove((folder + "/" + filePrefix + "00").c_str());
    remove((folder + "/" + filePrefix + "00").c_str());

    remove((folder + "/" + filePrefix + "00").c_str());
    remove((folder + "/" + filePrefix + "00").c_str());
}

void benchmark() {
    clearFiles(FOLDER, "blueprint");
    int trainIterations = 10000;
    int maxIterations = 500000;
    int playIterations = 100000;
    Logger::initBenchmark(FOLDER, "benchmark", DEVICE_OPTIONS.at(1), BLOCKSIZE, raiseSizes, trainIterations, maxIterations, playIterations);
    for (int currentIteration = trainIterations; currentIteration < maxIterations; currentIteration+= trainIterations) {
        std::chrono::system_clock::time_point initStart, trainStart, trainFinish;
        //gpu
        Logger::logStart(DEVICE_OPTIONS.at(1), BLOCKSIZE, trainIterations);

        initStart = std::chrono::system_clock::now();
        TexasHoldemTrainer trainer = TexasHoldemTrainer(FOLDER, "blueprint");
        trainStart = std::chrono::system_clock::now();
        Logger::logInit(initStart, trainStart);

        trainer.trainSequentiell(trainIterations, true);
        trainFinish = std::chrono::system_clock::now();
        Logger::logTraining(trainStart, trainFinish, trainIterations);

        GameMaster gameMaster = GameMaster(FOLDER, "blueprint");
        //PlayResult* result = gameMaster.playBlueprintVersusRandom(playIterations);
        PlayResult* result = gameMaster.playBlueprintVersusBlueprint(playIterations);

        Logger::logPlay(result, playIterations);

        trainer.schablone->roundInfos.at(3).at(0).bucketFunction->loadBucketFunction();
        size_t bucketListSize = trainer.schablone->roundInfos.at(3).at(0).bucketFunction->bucketList.size();
        size_t bucketSize = trainer.schablone->roundInfos.at(3).at(0).bucketFunction->size * 2;
        size_t bucketCount = bucketListSize / bucketSize;

        std::string fileSize = trainer.schablone->roundInfos.at(3).at(0).blueprintHandler->getFileSize();

        Logger::logBenchmark(FOLDER, "benchmark", currentIteration, playIterations, fileSize, bucketCount, initStart, trainStart, trainFinish, result);

        free(result);
    }

    
}

std::string getOptions(std::vector<string> options) {
    std::ostringstream optionsString;
    for (int i = 0; i < options.size(); i++) {
        optionsString << options.at(i) << " (" << i << ")" << (i == options.size()-1 ? ": " : ", ");
    }
    return optionsString.str();
}

void clear() {
   clearFiles(FOLDER, "blueprint");
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
    GameMaster gameMaster = GameMaster(FOLDER, "blueprint");
    //PlayResult* result = gameMaster.playBlueprintVersusRandom(iterations);
    PlayResult* result = gameMaster.playBlueprintVersusBlueprint(iterations);

    Logger::logPlay(result, iterations);
    
    free(result);
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
    TexasHoldemTrainer trainer = TexasHoldemTrainer(FOLDER,  "blueprint");
    trainStart = std::chrono::system_clock::now();
    Logger::logInit(initStart, trainStart);

    trainer.trainSequentiell(iterations, deviceOption == 1);
    trainFinish = std::chrono::system_clock::now();
    Logger::logTraining(trainStart, trainFinish, iterations);

    if (gDebug) {
        for (int i = 0; i < trainer.elapsedKernelTimes.size(); i++) {
            Logger::logToConsole(std::to_string(trainer.elapsedKernelTimes.at(i) /= iterations) + " ns");
        }
        for (int i = 0; i < trainer.elapsedCpuTimes.size(); i++) {
            Logger::logToConsole(std::to_string(trainer.elapsedCpuTimes.at(i) /= iterations) + " ns");
        }
        for (int i = 0; i < trainer.elapsedMemcpyTimes.size(); i++) {
            Logger::logToConsole(std::to_string(trainer.elapsedMemcpyTimes.at(i) /= iterations) + " ns");
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