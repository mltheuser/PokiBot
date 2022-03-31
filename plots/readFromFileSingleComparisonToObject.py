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
#benchmarkFile = open('benchmark0.txt', 'r')

preBenchmarkFile = open('pre_benchmarkcomparison_blueprint.txt', 'r')
#preBenchmarkFile = open('pre_benchmark0.txt', 'r')

for x in range(11):
    #skip first two lines with description + next 9 lines cause of pre_benchmark
    benchmarkFile.readline()

#skip first two lines with descriptions
preBenchmarkFile.readline()
preBenchmarkFile.readline()

PRE_LIST = [Record(*(line.split(','))) for line in preBenchmarkFile]

LIST = [Record(*(line.split(','))) for line in benchmarkFile]

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

plt.plot(iterations, winrate, label="Winrate")
plt.plot(iterations, rematch_winrate, label="Rematch winrate")
plt.plot(iterations, combined_winrate, label="Combined winrate")
plt.axhline(y=0.5, color='r', linestyle='-')

plt.xlabel('Iterations')
plt.ylabel('Winrate')
plt.title('Winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.ylim([0.35, 0.65])
plt.savefig('winrateProgression.pdf')
plt.savefig('winrateProgression.png')
plt.show()

plt.plot(iterations, payoff, label="Payoff")
plt.plot(iterations, rematch_payoff, label="Rematch payoff")
plt.plot(iterations, combined_payoff, label="Combined payoff")
plt.axhline(y=0, color='r', linestyle='-')

plt.xlabel('Iterations')
plt.ylabel('Payoff')
plt.title('Payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('payoffProgression.pdf')
plt.savefig('payoffProgression.png')
plt.show()

plt.plot(iterations, combined_winrate, label="Combined winrate")

plt.xlabel('Iterations')
plt.ylabel('Winrate')
plt.title('Combined winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedWinratePogression.pdf')
plt.savefig('combinedWinratePogression.png')
plt.show()

plt.plot(iterations, combined_winrate, label="Combined winrate")

plt.xlabel('Iterations')
plt.ylabel('Winrate')
plt.ylim([0.6, 0.64])
plt.title('Combined winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedWinratePogression2.pdf')
plt.savefig('combinedWinratePogression2.png')
plt.show()

plt.plot(iterations, combined_winrate, label="Combined winrate")
plt.axhline(y=0.5, color='r', linestyle='-')

plt.xlabel('Iterations')
plt.ylabel('Winrate')
plt.ylim([0.48, 0.51])
plt.title('Combined winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedWinratePogression3.pdf')
plt.savefig('combinedWinratePogression3.png')
plt.show()

plt.plot(iterations, combined_payoff, label="Combined payoff")

plt.xlabel('Iterations')
plt.ylabel('Payoff')
plt.title('Combined payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedPayoffProgression.pdf')
plt.savefig('combinedPayoffProgression.png')
plt.show()

plt.plot(iterations, combined_payoff, label="Combined payoff")

plt.xlabel('Iterations')
plt.ylabel('Payoff')
plt.ylim([10.5, 12.5])
plt.title('Combined payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedPayoffProgression2.pdf')
plt.savefig('combinedPayoffProgression2.png')
plt.show()

plt.plot(iterations, combined_payoff, label="Combined payoff")
plt.axhline(y=0, color='r', linestyle='-')

plt.xlabel('Iterations')
plt.ylabel('Payoff')
plt.ylim([10.5, 12.5])
plt.title('Combined payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('combinedPayoffProgression3.pdf')
plt.savefig('combinedPayoffProgression3.png')
plt.show()

plt.plot(iterations, bucket_counts, label="Bucket counts")

plt.xlabel('Iterations')
plt.ylabel('Bucket count')
plt.title('Bucket counts progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('bucketCountProgression.pdf')
plt.savefig('bucketCountProgression.png')
plt.show()

plt.plot(bucket_counts, combined_winrate, label="Bucket counts x combined winrate")

plt.xlabel('Bucket count')
plt.ylabel('Winrate')
plt.title('Bucket counts x combined winrate progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('bucketCountxCombinedWinrate.pdf')
plt.savefig('bucketCountxCombinedWinrate.png')
plt.show()

plt.plot(bucket_counts, combined_payoff, label="Bucket counts x combined payoff")

plt.xlabel('Bucket count')
plt.ylabel('Payoff')
plt.title('Bucket counts x combined payoff progression { 1, 5, 10, 25 }')
plt.legend()
plt.savefig('bucketCountxCombinedPayoff.pdf')
plt.savefig('bucketCountxCombinedPayoff.png')
plt.show()




