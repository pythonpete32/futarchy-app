import assert from 'assert'
import currentGainLoss from './currentGainLoss'

const mockPerformanceData = (trader, yesGainLoss, noGainLoss) => {
  return {
    trader,
    decisionId: 0,
    yesGainLoss,
    noGainLoss
  }
}

const mockDecisionData = (passed) => {
  return {
    decisionId: 0,
    passed
  }
}

describe('currentGainLoss', () => {
  describe('when given a trader address and performance array with data for that trader', () => {
    let performanceArray

    beforeEach(async () => {
      performanceArray = [
        mockPerformanceData('trader_0', 200, 300),
        mockPerformanceData('trader_1', 100, 400),
        mockPerformanceData('trader_0', 300, 500)
      ]
    })

    describe('when the decision has passed', () => {
      it('should return sum of yesGainLoss for each decision total with that trader address', () => {
        const decisionArray = [
          mockDecisionData(true)
        ]
        assert.equal(currentGainLoss('trader_0', performanceArray, decisionArray), 500)
      })
    })

    describe('when the decision has failed', () => {
      it('should return sum of noGainLoss for each decision total with that trader address', () => {
        const decisionArray = [
          mockDecisionData(false)
        ]
        assert.equal(currentGainLoss('trader_0', performanceArray, decisionArray), 800)
      })
    })
  })

  describe('when given a trader address and performance array without data for that trader', () => {
    it('should return 0', () => {
      const decisionArray = [
        mockDecisionData(false)
      ]
      const performanceArray = [
        mockPerformanceData('trader_1', 200, 300),
        mockPerformanceData('trader_1', 100, 400),
        mockPerformanceData('trader_1', 300, 500)
      ]
      assert.equal(currentGainLoss('trader_0', performanceArray, decisionArray), 0)
    })
  })
})
