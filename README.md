# Futarchy App

App for futarchy

## Setup

1. `npm install`

2. `npm run compile`

## Run

1. `npm run start:app`: builds the frontend to `dist/`

2. `npm run devchain`: starts a local aragon [devchain](https://hack.aragon.org/docs/cli-usage.html#aragon-devchain)

3. `npm run start:aragon`:
  * deploys contract dependencies
  * publishes the futarchy app
  * creates a new futarchy DAO instance
  * starts the aragon app

## Scripts

### `npm run devchain:reset`

Starts the devchain with `--reset`, which deletes existing ganache snapshots

**NOTE: aragon caches event data using indexdb. You need to clear your browser cache after the devchain is reset

## Sandbox Setup (for Component UI development)

Use this to develop components without having to depend on the "backend" smart contract environment:

1. First, `npm install`

2. Run `npm run start:app` to build the frontend to the `dist` dir and watch for changes.

3. Run `npm run start:sandbox` to serve the frontend at `http://localhost:8080`

4. Modify `./app/components/DecisionListEmptyState.js` to add the component you're working on. This is the default view, so you should see changes here when you refresh the browser.

If something breaks, just restart the `npm run start:app` and `npm run start:sandbox` processes.

## Mocking Component State

All components in `futarchy-app` are "stateless functional" components. This means they expect some state as input, and render UI based on this state. You can use hardcoded state to test these components. Here's an example:

```
// ./app/components/DecisionListEmptyState.js

import React from 'react'
// import ShowPanelButtonContainer from '../containers/ShowPanelButtonContainer'
import DecisionSummary from './DecisionSummary'

const mockDecision = {
  id: 123456,
  question: 'question will show up?'
}

const DecisionListEmptyState = () => (
  <DecisionSummary decision={mockDecision} />
  // <div>
  //   Nothing here yet...
  //   <br /> <br />

  //   <ShowPanelButtonContainer panelName="createDecisionMarket">
  //     New Decision
  //   </ShowPanelButtonContainer>
  // </div>
)

export default DecisionListEmptyState
```

This should display the `DecisionSummary` component with the state that we provided in `mockDecision`.

## Styling

We're using react [styled-components](https://www.styled-components.com/docs/basics), which allow you to add CSS within the component .js files. See `./app/components/AppHeader.js` for a good example of this.
