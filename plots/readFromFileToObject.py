import matplotlib.pyplot as plt

class Record(object):
    def __init__(self, ITERATIONS, BUCKET_COUNT, FILE_SIZE, INIT_TIME, TRAIN_TIME, WIN_PERCENTAGE, LOOSE_PERCENTAGE, DRAW_PERCENTAGE, WIN_PERCENTAGE_NO_DRAW, NORMALIZED_PAYOFF, REMATCH_WIN_PERCENTAGE, REMATCH_LOOSE_PERCENTAGE, REMATCH_DRAW_PERCENTAGE, REMATCH_WIN_PERCENTAGE_NO_DRAW, REMATCH_NORMALIZED_PAYOFF):
        super(Record, self).__init__()
        self.ITERATIONS = ITERATIONS
        self.BUCKET_COUNT = BUCKET_COUNT
        self.FILE_SIZE = FILE_SIZE
        self.INIT_TIME = INIT_TIME
        self.TRAIN_TIME = TRAIN_TIME
        self.WIN_PERCENTAGE = WIN_PERCENTAGE
        self.LOOSE_PERCENTAGE = LOOSE_PERCENTAGE
        self.DRAW_PERCENTAGE = DRAW_PERCENTAGE
        self.WIN_PERCENTAGE_NO_DRAW = WIN_PERCENTAGE_NO_DRAW
        self.NORMALIZED_PAYOFF = NORMALIZED_PAYOFF
        self.REMATCH_WIN_PERCENTAGE = REMATCH_WIN_PERCENTAGE
        self.REMATCH_LOOSE_PERCENTAGE = REMATCH_LOOSE_PERCENTAGE
        self.REMATCH_DRAW_PERCENTAGE = REMATCH_DRAW_PERCENTAGE
        self.REMATCH_WIN_PERCENTAGE_NO_DRAW = REMATCH_WIN_PERCENTAGE_NO_DRAW
        self.REMATCH_NORMALIZED_PAYOFF = REMATCH_NORMALIZED_PAYOFF


benchmarkFile = open('benchmarkcomparison_blueprint.txt', 'r')
benchmarkFile2 = open('benchmark0.txt', 'r')

preBenchmarkFile = open('pre_benchmarkcomparison_blueprint.txt', 'r')
preBenchmarkFile2 = open('pre_benchmark0.txt', 'r')

for x in range(11):
    #skip first two lines with description + next 9 lines cause of pre_benchmark
    benchmarkFile.readline()
    benchmarkFile2.readline()

#skip first two lines with descriptions
preBenchmarkFile.readline()
preBenchmarkFile.readline()
preBenchmarkFile2.readline()
preBenchmarkFile2.readline()

LIST = [Record(*(line.split(','))) for line in benchmarkFile]

PRE_LIST = [Record(*(line.split(','))) for line in preBenchmarkFile]

#skip first two lines with descriptions


LIST_2 = [Record(*(line.split(','))) for line in benchmarkFile2]

PRE_LIST_2 = [Record(*(line.split(','))) for line in preBenchmarkFile2]

### plotting
iterations = []

winrate = []
rematch_winrate = []
payoff = []
rematch_payoff = []
combined_winrate = []
combined_payoff = []

bucket_counts = []

for entry in PRE_LIST:
    iterations.append(int(entry.ITERATIONS) + 1000)

    winrate.append(float(entry.WIN_PERCENTAGE_NO_DRAW))
    payoff.append(float(entry.NORMALIZED_PAYOFF))
    rematch_winrate.append(float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW))
    rematch_payoff.append(float(entry.REMATCH_NORMALIZED_PAYOFF))
    combined_winrate.append((float(entry.WIN_PERCENTAGE_NO_DRAW) + float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW)) / 2)
    combined_payoff.append((float(entry.NORMALIZED_PAYOFF) + float(entry.REMATCH_NORMALIZED_PAYOFF)) / 2)

    bucket_counts.append(int(entry.BUCKET_COUNT))

for entry in LIST:
    iterations.append(int(entry.ITERATIONS) + 10000)

    winrate.append(float(entry.WIN_PERCENTAGE_NO_DRAW))
    payoff.append(float(entry.NORMALIZED_PAYOFF))
    rematch_winrate.append(float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW))
    rematch_payoff.append(float(entry.REMATCH_NORMALIZED_PAYOFF))
    combined_winrate.append((float(entry.WIN_PERCENTAGE_NO_DRAW) + float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW)) / 2)
    combined_payoff.append((float(entry.NORMALIZED_PAYOFF) + float(entry.REMATCH_NORMALIZED_PAYOFF)) / 2)

    bucket_counts.append(int(entry.BUCKET_COUNT))

winrate2 = []
rematch_winrate2 = []
payoff2 = []
rematch_payoff2 = []
combined_winrate2 = []
combined_payoff2 = []

for entry in PRE_LIST_2:
    winrate2.append(float(entry.WIN_PERCENTAGE_NO_DRAW))
    payoff2.append(float(entry.NORMALIZED_PAYOFF))
    rematch_winrate2.append(float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW))
    rematch_payoff2.append(float(entry.REMATCH_NORMALIZED_PAYOFF))
    combined_winrate2.append((float(entry.WIN_PERCENTAGE_NO_DRAW) + float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW)) / 2)
    combined_payoff2.append((float(entry.NORMALIZED_PAYOFF) + float(entry.REMATCH_NORMALIZED_PAYOFF)) / 2)

for entry in LIST_2:
    winrate2.append(float(entry.WIN_PERCENTAGE_NO_DRAW))
    payoff2.append(float(entry.NORMALIZED_PAYOFF))
    rematch_winrate2.append(float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW))
    rematch_payoff2.append(float(entry.REMATCH_NORMALIZED_PAYOFF))
    combined_winrate2.append((float(entry.WIN_PERCENTAGE_NO_DRAW) + float(entry.REMATCH_WIN_PERCENTAGE_NO_DRAW)) / 2)
    combined_payoff2.append((float(entry.NORMALIZED_PAYOFF) + float(entry.REMATCH_NORMALIZED_PAYOFF)) / 2)

plt.plot(iterations, winrate, label="Winrate")
plt.plot(iterations, rematch_winrate, label="Rematch winrate")
plt.plot(iterations, combined_winrate, label="Combined winrate")

plt.plot(iterations, winrate2, label="Winrate vs random")
plt.plot(iterations, rematch_winrate2, label="Rematch winrate vs random")
plt.plot(iterations, combined_winrate2, label="Combined winrate vs random")

plt.xlabel('Iterations')
plt.ylabel('Winrate')
plt.title('Winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('winrateProgression.pdf')
plt.savefig('winrateProgression.png')
plt.show()

plt.plot(iterations, payoff, label="Payoff")
plt.plot(iterations, rematch_payoff, label="Rematch payoff")
plt.plot(iterations, combined_payoff, label="Combined payoff")

plt.plot(iterations, payoff2, label="Payoff vs random")
plt.plot(iterations, rematch_payoff2, label="Rematch payoff vs random")
plt.plot(iterations, combined_payoff2, label="Combined payoff vs random")

plt.xlabel('Iterations')
plt.ylabel('Payoff')
plt.title('Payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('payoffProgression.pdf')
plt.savefig('payoffProgression.png')
plt.show()

plt.plot(iterations, combined_winrate, label="Combined winrate")
plt.plot(iterations, combined_winrate2, label="Combined winrate vs random")

plt.xlabel('Iterations')
plt.ylabel('Winrate')
plt.title('Combined winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedWinratePogression.pdf')
plt.savefig('combinedWinratePogression.png')
plt.show()

plt.plot(iterations, combined_payoff, label="Combined payoff")
plt.plot(iterations, combined_payoff2, label="Combined payoff vs random")

plt.xlabel('Iterations')
plt.ylabel('Payoff')
plt.title('Combined payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedPayoffProgression.pdf')
plt.savefig('combinedPayoffProgression.png')
plt.show()

plt.plot(iterations, bucket_counts, label="Bucket Counts")

plt.xlabel('Iterations')
plt.ylabel('Bucket count')
plt.title('Bucket counts progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('bucketCountProgression.pdf')
plt.savefig('bucketCountProgression.png')
plt.show()

plt.plot(bucket_counts, combined_winrate, label="Bucket Counts x Combined winrate")
plt.plot(bucket_counts, combined_winrate2, label="Bucket Counts x Combined winrate vs random")

plt.xlabel('Bucket count')
plt.ylabel('Winrate')
plt.title('Bucket counts x combined winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('bucketCountxCombinedWinrate.pdf')
plt.savefig('bucketCountxCombinedWinrate.png')
plt.show()

plt.plot(bucket_counts, combined_payoff, label="Bucket Counts x Combined payoff")
plt.plot(bucket_counts, combined_payoff2, label="Bucket Counts x Combined payoff vs random")

plt.xlabel('Bucket count')
plt.ylabel('Payoff')
plt.title('Bucket counts x combined payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('bucketCountxCombinedPayoff.pdf')
plt.savefig('bucketCountxCombinedPayoff.png')
plt.show()




