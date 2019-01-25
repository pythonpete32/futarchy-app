import React from 'react'
import _ from 'lodash'
import { withRouter, matchPath } from 'react-router-dom'
import { connect } from 'react-redux'
import AppHeader from '../components/AppHeader'

const getDecisionRouteParams = pathname => {
  const path = matchPath(pathname, {
    path: `/decision/:decisionId`,
  })
  return path ? path.params : {}
}

const findDecisionById = (decisions, decisionId) => _.find(
  decisions,
  {  decisionId }
)

const mapStateToProps = (state, ownProps) => ({
  decision: findDecisionById(
    state.decisionMarkets,
    getDecisionRouteParams(ownProps.location.pathname).decisionId
  )
})

export default withRouter(connect(
  mapStateToProps
)(AppHeader))
