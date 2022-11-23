A counterfactual regret-based poker bot. Details can be found in the [submission](https://github.com/mltheuser/PokiBot/files/10073587/PJS22.pdf) on the project under Group 3.

# Setup
Das Projekt kommt mit einer Projektconfig für Visual Studio.
Steht dir ein Windows-Rechner und damit Visual Studio zur Verfügung, besteht das Setup daher aus ein paar einfachen Schritten:

1. Clone the repository using git clone https://github.com/Kecksbox/PokiBot.git.
2. Open the Projekt test_proj.sln in Visual Studio.
3. Go to Projekt > Build Customizations > And check your cuda version.
4. Erstelle einen leeren Ordner mit dem Namen "outputs" im RootVerzeichnis.
5. Build.
6. Enjoy!

# Usage

Die Anwendung wird per commandline bedient.

Schritt 1 wähle den Modus (Jede Wahl hier bringt dich am Ende wieder zurück zu diesem Schritt):
0. clean -> Löscht alle Dateien für Buckets und Strategien.
1. train -> Trainiert den Bot. Das Training ist abhängig von der nächsten Eingabe als CPU oder GPU Version erhältlich.
2. play -> Lässt den Bot gegen einen random Bot, sich selbst oder den Nutzer spielen.
3. benchmark -> Testet die Stärke des Bots und Effizienz des Trainings.
4. exit - Beendet das Programm.

# Customization
Nicht alles kann über die commandline eingestellt werden. Einige Dinge sind auch fester Bestandteil des Codes.
Hier ist, wo du die wichtigsten Dinge finden kannst:

- Die RaiseSizes können als vector in der RaiseBuckets.cuh gefunden werden. Stell sicher, dass du sie aufsteigend sortierst.
- Spielen wird über ein Zusammenspiel von Gamemaster und Actors realisiert. Actors haben eine einzige Methode act(infoset), die den nächsten Zug des Spieler ausgibt. Für das OnlineSetting würde der GameMaster durch die Schnittstelle ersetzt und vor dem Akteur ein Kommunikationsmodul nötig, dass InfoSets und Aktionen in das jeweils erwartete Format übersetzt. Ausgangspunkt sollte hier der BlueprintActor sein. Also der Actor, der streng nach den gelernten Blueprints spielt.
- Die Buckets kannst du anpassen indem du die getBucket(cards) Methode in BucketFunction.cu umschreibst.
- In Trainer.cuh gibt es noch zwei anpassbare Konstanten von Interesse. gDebug schaltet den Profiler an. BLOCKSIZE kontrolliert die BlockSize beim Aufruf von CudaKernels.

# Plots
Im Plots-Ordner findet man verschiedene Python-Dateien. Die durch das Benchmarking entstehenden .txt Dateien können in diesen Ordner kopiert werden und nach eventuell nötigen Änderungen der Pfade in den pythonSkripten für das Erstellen der Graphen in unserer Abgabe verwendet werden.
