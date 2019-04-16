class SmoothenValue {

    private let beta: Double
    private var n = 0
    var movAvg = 0.0
    var smooth = 0.0

    init(beta: Double) {
        self.beta = beta
    }

    func addValue(_ val: Double) {
        n += 1
        movAvg = beta * movAvg + (1.0 - beta) * val
        smooth = movAvg / (1 - beta ** n)
    }

}