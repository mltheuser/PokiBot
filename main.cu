#ifndef __main__
#define __main__

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "Trainer.cuh"
#include "GameMaster.cuh"
#include "Logger.cuh"
#include "RaiseBuckets.cuh"

#include <stdio.h>
#include <cstdio>
#include <vector>
#include <time.h>
#include <string>
#include <filesystem>

using std::cout;
using std::endl;
using std::cin;
using std::vector;

vector<string> CONSOLE_OPTIONS = { "clear", "train", "play", "benchmark", "exit" };
vector<string> DEVICE_OPTIONS = { "cpu", "gpu" };
vector<string> PLAY_OPTIONS = { "vsRandom" };
string GET_FILENAME = "Input filename (blueprint): ";
string GET_COMPARISON_FILENAME = "Input filename (play vs random): ";
string GET_ITERATIONS = "Input number of iterations: ";
string GET_WRONG_INPUT = "Falsche Eingabe ... zurück zur Hauptauswahl";
string GET_BENCHMARKING_INPUT = "Input filename (blueprint), comparison_1 (comparison), comparison_2 (random), trainMaxIterations (200k), trainIterationSteps (5k), playIterations (25k)";
string FOLDER = "outputs";
string COMPARISON_1 = "comparison";
string COMPARISON_2 = "comparison_2";

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
    string filename, comparison1, comparison2;
    int trainMaxIterations, tranIterationSteps, playIterations;
    bool comparison2Random;
    
    cout << GET_BENCHMARKING_INPUT;

    cin >> filename;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (filename == "0") filename = "blueprint";

    cin >> comparison1;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (comparison1 == "0") comparison1 = COMPARISON_1;

    cin >> comparison2;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (comparison2 == "0") comparison2Random = true;

    cin >> trainMaxIterations;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (trainMaxIterations == 0) trainMaxIterations = 200000;

    cin >> tranIterationSteps;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (tranIterationSteps == 0) tranIterationSteps = 5000;

    cin >> playIterations;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (playIterations == 0) playIterations = 25000;

    Logger::initBenchmark(FOLDER, "benchmark" + comparison1, DEVICE_OPTIONS.at(1), BLOCKSIZE, raiseSizes, tranIterationSteps, trainMaxIterations, playIterations);
    Logger::initBenchmark(FOLDER, "benchmark" + comparison2, DEVICE_OPTIONS.at(1), BLOCKSIZE, raiseSizes, tranIterationSteps, trainMaxIterations, playIterations);

    TexasHoldemTrainer trainer = TexasHoldemTrainer(FOLDER, filename);
    GameMaster gameMaster = GameMaster(FOLDER, filename);

    for (int currentIteration = tranIterationSteps; currentIteration < trainMaxIterations; currentIteration+= tranIterationSteps) {
        std::chrono::system_clock::time_point initStart, trainStart, trainFinish;
        //gpu
        Logger::logStart(DEVICE_OPTIONS.at(1), BLOCKSIZE, tranIterationSteps);

        initStart = std::chrono::system_clock::now();
        
        trainStart = std::chrono::system_clock::now();
        Logger::logInit(initStart, trainStart);

        trainer.trainSequentiell(tranIterationSteps, true);
        trainFinish = std::chrono::system_clock::now();
        Logger::logTraining(trainStart, trainFinish, tranIterationSteps);

        
        PlayResult* result = gameMaster.playBlueprintVersusBlueprint(playIterations, comparison1);
        PlayResult* result2;

        if (comparison2Random) {
            result2 = gameMaster.playBlueprintVersusRandom(playIterations);
        }
        else {
            result2 = gameMaster.playBlueprintVersusBlueprint(playIterations, comparison2);
        }

        Logger::logPlay(result, playIterations);
        Logger::logPlay(result2, playIterations);
        

        trainer.schablone->roundInfos.at(3).at(0).bucketFunction->loadBucketFunction();
        size_t bucketListSize = trainer.schablone->roundInfos.at(3).at(0).bucketFunction->bucketList.size();
        size_t bucketSize = trainer.schablone->roundInfos.at(3).at(0).bucketFunction->size * 2;
        size_t bucketCount = bucketListSize / bucketSize;

        std::string fileSize = trainer.schablone->roundInfos.at(3).at(0).blueprintHandler->getFileSize();

        Logger::logBenchmark(FOLDER, "benchmark" + comparison1, currentIteration, playIterations, fileSize, bucketCount, initStart, trainStart, trainFinish, result);

        Logger::logBenchmark(FOLDER, "benchmark" + comparison2, currentIteration, playIterations, fileSize, bucketCount, initStart, trainStart, trainFinish, result2);


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
    string filename, comparisonFilename;

    cout << GET_ITERATIONS;
    cin >> iterations;
    
    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    cout << GET_FILENAME;
    cin >> filename;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (filename == "0") filename = "blueprint";

    cout << GET_COMPARISON_FILENAME;
    cin >> comparisonFilename;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }


    GameMaster gameMaster = GameMaster(FOLDER, filename);
    PlayResult* result;

    if (comparisonFilename == "0") {
        gameMaster.playBlueprintVersusRandom(iterations);
    }
    else {
        gameMaster.playBlueprintVersusBlueprint(iterations, comparisonFilename);
    }

    Logger::logPlay(result, iterations);
    
    free(result);
}

void train() {
    int deviceOption, iterations;
    string filename;
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

    cout << GET_FILENAME;
    cin >> filename;

    if (!cin) {
        cout << GET_WRONG_INPUT << endl;
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        return;
    }

    if (filename == "0") filename = "blueprint";

    Logger::logStart(DEVICE_OPTIONS.at(deviceOption), BLOCKSIZE, iterations);

    initStart = std::chrono::system_clock::now();
    TexasHoldemTrainer trainer = TexasHoldemTrainer(FOLDER,  filename);
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
    //srand(0);
    srand(std::chrono::system_clock::now().time_since_epoch().count());

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