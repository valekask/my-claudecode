# Architecture Guideline

This guide describes which steps need to follow to build stable and maintainable application.

-   [1) Lean Components](#1-lean-components)
-   [2) Layers](#2-layers)
-   [3) Modular design](#3-modular-design)
-   [4) Data flow](#4-data-flow)
-   [Q&A](#qa)
-   [Style guidelines worth giving a second read](#style-guidelines-worth-giving-a-second-read)
-   [Resources](#resources)

## 1) Lean Components

Modern frontend application builds on top of component-based acrhitecture. Application is a collection of components.
Each component should be simple and focused on one functionality at a time. Decomple presentation layer from application logic.
For this goal, split components into container and presentational components. Moreover, keep all business logic in component-specific services.

#### Container components

-   Contain all the state needed for the child component
-   Transform data into a shape that is most convenient for the presentational component
-   Translate events from the presentational component
-   Stateful

#### Presentational components

-   Present piece of application state that is passed through input properties
-   Delegate user interaction up to the container components via output events
-   Stateless, but might keep local UI state which is part of UI behaviour
-   Should not know about state management layer

#### Component-specific Services

-   Keep behaviour logic
-   Encapsulate business logic
-   Transform from data to view model
-   Validate data and user input
-   Handle application-specific events
-   Should not know about state management layer

Some architecture guides recommend to use Presenters or Facades to encapsulate complex presentational logic.
I think such approaches more feat for very large apps and might be overcomplicated for medium-size apps.

## 2) Layers

Separate concerns into layers to establish a well organized system where each part
fulfills a meaningful and intuitive role while maximizing its ability to adapt to change.
Each layer has it's own scope of responsibility and rules how to commmunicate with other layers.

In our application, we separate functionality into these layers:

-   presentation (presentational components, view models, pipes, directives)
-   business logic (containers, component-specific services, data models)
-   state management (store, actions, selectors)
-   data access (data services)
-   core (authorization, security, sessions, interceptors)

When organizing behavior, the following goals should be sought:

-   eliminate the duplication of functionality
-   restrict the scope of work to a maintainable size
-   restrict the scope of work to the description of the containing boundary
-   restrict the scope of work to the inherent behavior of the containing boundary
-   minimize external dependencies
-   maximize the potential for reuse

Main goals of concerns separation:

-   separate different concerns and levels of abstraction
-   separate low level implementation details and high level policies
-   easier time changing the details without breaking the component

## 3) Modular design

Slice the application into feature modules representing different business functionalities.
Deconstruct system into smaller pieces for better maintainability. Use lazy-loading technique to speed up application loading.

-   Use feature-modules to encapsulate every components, directives or pipes related to business area
-   Use shared-modules to encapsulate common utility components, directives or pipes
-   Use core-modules to keep application-wide singleton services

## 4) Data flow

Follow a **data-driven approach**: code should work around the data. Developers must clearly understand the data flow from initial point to the view.

### Data Flow Layers

```
┌─────────────────────────────────────────────────────────────────┐
│  DataService         Fetches data from API                      │
│         ↓                                                       │
│  ComponentStore      Stores & transforms data (preferred)       │
│         ↓            - OR: Global NgRx Store (cross-feature)    │
│         ↓            - OR: Simple service (trivial cases)       │
│  Container           Orchestrates data flows & user actions     │
│         ↓                                                       │
│  Presentational      Displays data via @Input, emits @Output    │
└─────────────────────────────────────────────────────────────────┘
```

### State Management Selection

| Scope | Solution | When to Use |
|-------|----------|-------------|
| **Feature/Component** | NgRx ComponentStore | Default choice. Lifecycle tied to component. |
| **Cross-feature** | Global NgRx Store | Shared state needed by multiple unrelated features |
| **Trivial** | Plain service | Single observable, no complex state transitions |

**Prefer ComponentStore** for feature-level state. Benefits:
- Automatic cleanup when component destroys (no memory leaks)
- Centralized empty/loading/error state handling
- Explicit state shape visible at top of file
- Rich RxJS integration with effects, selectors, updaters
- Easier testing (mock store, test component in isolation)

### ComponentStore Pattern

See `libs/dashboard/feature-graph/src/lib/graphs/sorted-list/services/graph-sorted-list.store.ts` for reference.

```typescript
// 1. Define explicit state shape
export class FeatureStoreState {
    data: Item[];
    loading: boolean;
    error: boolean;
    // ... all state visible here
}

// 2. Expose selectors for each state slice
readonly data$ = this.select(state => state.data);
readonly loading$ = this.select(state => state.loading);

// 3. Create derived selectors for complex UI logic
readonly emptyState$ = this.select(
    this.data$, this.loading$, this.error$,
    (data, loading, error) => {
        if (loading) return EmptyStateType.LOADING;
        if (error) return EmptyStateType.ERROR;
        if (data.length === 0) return EmptyStateType.EMPTY;
        return null;
    }
);

// 4. Updaters for state mutations
readonly setData = this.updater<Item[]>((state, data) => ({ ...state, data }));

// 5. Effects for side effects (API calls)
readonly loadData$ = this.effect<Params>(params$ =>
    params$.pipe(
        switchMap(params => this.dataService.fetch(params).pipe(
            tap(result => this.patchState({ data: result, loading: false })),
            catchError(error => { this.patchState({ error: true }); return EMPTY; })
        ))
    )
);
```

### Data Transformation Location

| Transformation | Where | Example |
|----------------|-------|---------|
| API response → domain model | Effect or DataService | `processData()` in effect |
| Domain model → view model | Selector | `emptyState$` selector |
| User input → API request | Container or Updater | Form value → criteria |

### Unidirectional Data Flow

- Container components pass state down to presentational components via `@Input`
- Presentational components emit events up via `@Output`
- Presentational components **never modify data locally**
- State changes flow: User Action → Container → Store → Selector → Template

### Reactive Patterns

- Use observable streams throughout (`async` pipe in templates)
- Prefer `OnPush` change detection strategy
- Avoid `ngOnChanges` for detecting value changes
- Use `distinctUntilChanged`, `debounceTime` to control data flow

### Anti-patterns to Avoid

| Anti-pattern | Problem | Solution |
|--------------|---------|----------|
| State in presentational component | Breaks unidirectional flow | Move to container or store |
| Multiple sources of truth | Inconsistent state | Single store per feature |
| Direct API calls in component | Hard to test, no caching | Use DataService + Store |
| Manual subscriptions without cleanup | Memory leaks | Use `async` pipe or `takeUntilDestroyed` |
| Complex logic in template | Hard to test, poor performance | Move to selector or presenter |
| `ngOnChanges` for derived state | Imperative, error-prone | Use reactive selectors |

## Q&A

#### [Difference between class and interface in Typescript](https://stackoverflow.com/questions/40973074/difference-between-interfaces-and-classes-in-typescript)

-   Use `Class` everywhere for consistency.

#### [How to detect when an @Input() value changes in Angular?](https://stackoverflow.com/questions/38571812/how-to-detect-when-an-input-value-changes-in-angular/44686085)

#### [Difference between constructor vs ngOnInit in Angular](https://stackoverflow.com/questions/35763730/difference-between-constructor-and-ngoninit)

#### [How can I select an element in a component template?](https://stackoverflow.com/questions/32693061/how-can-i-select-an-element-in-a-component-template)

## Style guidelines worth giving a second read

#### Extract non-presentational logic to services

[Style 05–15: Delegate complex component logic to services](https://angular.io/guide/styleguide#delegate-complex-component-logic-to-services)

It tells us to extract non-presentational logic to services. Next, it tells us to keep components simple and focused on what they’re supposed to do. In other words, we should minimise logic in templates, delegate logic away from component models, keep component small, so no 1,000 lines of code components.

#### Don’t put presentation logic in the template

[Style 05–17: Put presentation logic in the component class](https://angular.io/guide/styleguide#put-presentation-logic-in-the-component-class)

Templates should worry about declarative DOM manipulation and event binding, not about implementation details.

#### Don’t create a component when a directive will do what you need

[Style 06–01: Use directives to enhance an element](https://angular.io/guide/styleguide#use-directives-to-enhance-an-element)

This guiding principle reminds us that we should not always be jumping to using a component straightaway. In fact, if no template is needed or the DOM changes can be reflected in the host element itself, an attribute directive will do good by us.

#### Do one thing and do it well

[Style 07–02: Single responsibility](https://angular.io/guide/styleguide#single-responsibility-1)

It recommends us to create services that encapsulate logic from a single horizontal layer at a single abstraction level.

#### Component level services

[Style 07–03: Providing a service](https://angular.io/guide/styleguide#providing-a-service)

It tells us about different between root and component level services.

#### Extract non-presentational concerns to services

[Style 08–01: Talk to the server through a service](https://angular.io/guide/styleguide#talk-to-the-server-through-a-service)

It tells us to delegate task of data manupulation to a service so that components do not have to know or worry about the details.

## Resources

-   [Lean components](https://dev.to/this-is-angular/lean-angular-components-1abl)
-   [Container components](https://dev.to/this-is-angular/container-components-with-angular-4o05)
-   [Presentational components](https://dev.to/this-is-angular/presentational-components-with-angular-3961)
-   [Presenters](https://dev.to/this-is-angular/presenters-with-angular-2l7l)
-   [The Art of Separation of Concerns](http://aspiringcraftsman.com/2008/01/03/art-of-separation-of-concerns/)
-   [Anatomy of a large Angular application](https://medium.com/@krposlek/anatomy-of-a-large-angular-application-f098e5e36994)
