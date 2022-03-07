#ifndef __Logger__
#define __Logger__

#include <iostream>
#include <fstream>

class Logger {
public:
    static void log(std::string logText) {
        std::cout << logText << std::endl;
    }

    static void logToFile(std::string saveText) {
        std::string path = "log.txt";
        std::ofstream write;

        write.open(path.c_str(), std::ios::out | std::ios::binary | std::ios::app);

        write << saveText;
        write.close();
    }
};

#endif