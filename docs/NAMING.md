# Naming Guideline

Naming is an important part of writing readable and maintainable code. The following best practices can help you achieve that goal.

-   [English language](#english-language)
-   [Naming convention](#naming-convention)
-   [S-I-D](#s-i-d)
-   [Avoid abbreviations](#avoid-abbreviations)
-   [Avoid context duplication](#avoid-context-duplication)
-   [Meaningful boolean name](#meaningful-boolean-name)
-   [Reflect the expected result](#reflect-the-expected-result)
-   [Naming functions](#naming-functions)
    -   [A/HC/LC pattern](#ahclc-pattern)
        -   [Actions](#actions)
        -   [Context](#context)
        -   [Prefixes](#prefixes)
-   [Singular and Plurals](#singular-and-plurals)
-   [Resources](#resources)

---

## English language

Use English language when naming your variables and functions.

```js
/* Bad */
const primerNombre = 'Gustavo';
const amigos = ['Kate', 'John'];

/* Good */
const firstName = 'Gustavo';
const friends = ['Kate', 'John'];
```

> Like it or not, English is the dominant language in programming: the syntax of all programming languages is written in English, as well as countless documentations and educational materials. By writing your code in English you dramatically increase its cohesiveness.

## Naming convention

Use the same name for the same thing, throughout your code. If a precedent already exists outside your API that users are likely to know, follow that precedent.

```js
/* Bad */
const page_count = 5;
const shouldUpdate = true;

/* Good */
const pageCount = 5;
const shouldUpdate = true;

/* Good as well */
const page_count = 5;
const should_update = true;
```

The goal is to take advantage of what the user already knows. This includes their knowledge of the problem domain itself, the conventions of the core libraries, and other parts of your own API. By building on top of those, you reduce the amount of new knowledge they have to acquire before they can be productive.

## S-I-D

A name must be _short_, _intuitive_ and _descriptive_:

-   **Short**. A name must not take long to type and, therefore, remember;
-   **Intuitive**. A name must read naturally, as close to the common speech as possible;
-   **Descriptive**. A name must reflect what it does/possesses in the most efficient way.

```js
/* Bad */
const a = 5; // "a" could mean anything
const isPaginatable = a > 10; // "Paginatable" sounds extremely unnatural
const shouldPaginatize = a > 10; // Made up verbs are so much fun!

/* Good */
const postCount = 5;
const hasPagination = postCount > 10;
const shouldPaginate = postCount > 10; // alternatively
```

## Avoid abbreviations

Do **not** use contractions. They contribute to nothing but decreased readability of the code. Finding a short, descriptive name may be hard, but contraction is not an excuse for not doing so.

```js
/* Bad */
const onItmClk = () => {};

/* Good */
const onItemClick = () => {};
```

## Avoid context duplication

A name should not duplicate the context in which it is defined. Always remove the context from a name if that doesn't decrease its readability.

```js
class MenuItem {
  /* Method name duplicates the context (which is "MenuItem") */
  handleMenuItemClick = (event) => { ... }

  /* Reads nicely as `MenuItem.handleClick()` */
  handleClick = (event) => { ... }
}
```

## Meaningful boolean name

Most boolean names have conceptually "positive" and "negative" forms, such as "enabled" and "disabled", "open" and "closed", etc.
Prefer the positive or more fundamental one. Boolean members are often nested inside logical expressions, including negation operators. If your property itself reads like a negation, it’s harder for the reader to mentally perform the double negation and understand what the code means.

```js
/* Bad */
if (!socket.isDisconnected && !database.isEmpty) {
    socket.write(database.read());
}

/* Good */
if (socket.isConnected && database.hasData) {
    socket.write(database.read());
}
```

With some properties, the negative form is what users overwhelmingly need to use. Choosing the positive case would force them to negate the property with ! everywhere. Instead, it may be better to use the negative case for that property.
See [Reflect the expected result](#reflect-the-expected-result) rule.

Good boolean names tend to start with one of a few kinds of verbs:

-   a form of "to be": isEnabled, wasShown, willFire. These are, by far, the most common.
-   an auxiliary verb: hasElements, canClose, shouldConsume, mustSave.

> If context is clear, "is" prefix might be omitted to makes name shorter.

A boolean name should never sound like a command to tell the object to do something.

```js
/* Bad */
empty; // Adjective or verb?
withElements; // Sounds like it might hold elements.
closeable; // Sounds like an interface. "canClose" reads better as a sentence.
closingWindow; // Returns a bool or a window?
showPopup; // Sounds like it shows the popup.

/* Good */
isEmpty;
hasElements;
canClose;
closesWindow;
canShowPopup;
hasShownPopup;
```

> **Exception**: Input properties in Angular components sometimes use imperative verbs for boolean setters because these setters are invoked in templates, not from other code.

## Reflect the expected result

A name should reflect the expected result.

```jsx
/* Bad */
const hasData = itemCount > 3;
return <Button disabled={!enabled} />;

/* Good */
const disabled = itemCount <= 3;
return <Button disabled={disabled} />;
```

---

# Naming functions

## A/HC/LC Pattern

There is a useful pattern to follow when naming functions:

```
prefix? + action (A) + high context (HC) + low context? (LC)
```

Take a look at how this pattern may be applied in the table below.

| Name                   | Prefix   | Action (A) | High context (HC) | Low context (LC) |
| ---------------------- | -------- | ---------- | ----------------- | ---------------- |
| `getUser`              |          | `get`      | `User`            |                  |
| `getUserMessages`      |          | `get`      | `User`            | `Messages`       |
| `onClickOutside`       | `on`     |            | `Click`           | `Outside`        |
| `shouldDisplayMessage` | `should` | `Display`  | `Message`         |                  |

> **Note:** The order of context affects the meaning of a variable. For example, `shouldUpdateComponent` means _you_ are about to update a component, while `shouldComponentUpdate` tells you that _component_ will update on itself, and you are but controlling when it should be updated.
> In other words, **high context emphasizes the meaning of a variable**.

---

## Actions

The verb part of your function name. The most important part responsible for describing what the function _does_.

### `get`

Accesses data immediately (i.e. shorthand getter of internal data).

```js
function getFruitCount() {
    return this.fruits.length;
}
```

> See also [compose](#compose).

### `set`

Sets a variable in a declarative way, with value `A` to value `B`.

```js
let fruits = 0;

function setFruits(nextFruits) {
    fruits = nextFruits;
}

setFruits(5);
console.log(fruits); // 5
```

### `reset`

Sets a variable back to its initial value or state.

```js
const initialFruits = 5;
let fruits = initialFruits;
setFruits(10);
console.log(fruits); // 10

function resetFruits() {
    fruits = initialFruits;
}

resetFruits();
console.log(fruits); // 5
```

### `fetch`

Request for some data, which takes some indeterminate time (i.e. async request).

```js
function fetchPosts(postCount) {
  return fetch('https://api.dev/posts', {...})
}
```

### `remove`

Removes something _from_ somewhere.

For example, if you have a collection of selected filters on a search page, removing one of them from the collection is `removeFilter`, **not** `deleteFilter` (and this is how you would naturally say it in English as well):

```js
function removeFilter(filterName, filters) {
    return filters.filter(name => name !== filterName);
}

const selectedFilters = ['price', 'availability', 'size'];
removeFilter('price', selectedFilters);
```

> See also [delete](#delete).

### `delete`

Completely erases something from the realms of existence.

Imagine you are a content editor, and there is that notorious post you wish to get rid of. Once you clicked a shiny "Delete post" button, the CMS performed a `deletePost` action, **not** `removePost`.

```js
function deletePost(id) {
    return database.find({ id }).delete();
}
```

> See also [remove](#remove).

> `remove` or `delete`?
>
> When the difference between remove and delete is not so obvious to you,
> I'd suggest looking at their opposite actions - `add` and `create`.
> The key difference between `add` and `create` is that `add` needs a _destination_
> while `create` requires _no destination_. You `add` an item to _somewhere_, but you don't `create` it to _somewhere_.
> Simply pair `remove` with `add` and `delete` with `create`.

### `compose`

Creates new data from the existing one. Mostly applicable to strings, objects, or functions.

```js
function composePageUrl(pageName, pageId) {
    return pageName.toLowerCase() + '-' + pageId;
}
```

> See also [get](#get).

### `convert`

Transform data in some different form or representation.

```js
function convertData(data) {
  return data.map(d => { ... })
}
```

---

## Context

A domain that a function operates on.

A function is often an action on _something_. It is important to state what its operable domain is, or at least an expected data type.

```js
/* A pure function operating with primitives */
function filter(list, predicate) {
    return list.filter(predicate);
}

/* Function operating exactly on posts */
function getRecentPosts(posts) {
    return filter(posts, post => post.date === Date.now());
}
```

> Some language-specific assumptions may allow omitting the context. For example, in JavaScript, it's common that `filter` operates on Array. Adding explicit `filterArray` would be unnecessary.

--

## Prefixes

Prefix enhances the meaning of a variable. It is rarely used in function names.

### `is`

Describes a characteristic or state of the current context (usually `boolean`).
If context is clear, "is" prefix might be omitted to makes name shorter.

```js
const color = 'blue';
const isBlue = color === 'blue'; // characteristic
const isPresent = true; // state

if (isBlue && isPresent) {
    console.log('Blue is present!');
}
```

### `on`

Uses to prefix callback method for an event.

```js
function onLinkClick() {
    console.log('Clicked a link!');
}

link.addEventListener('click', onLinkClick);
```

### `has`

Describes whether the current context possesses a certain value or state (usually `boolean`).

```js
/* Bad */
const isProductsExist = productsCount > 0;
const areProductsPresent = productsCount > 0;

/* Good */
const hasProducts = productsCount > 0;
```

### `should`

Reflects a positive conditional statement (usually `boolean`) coupled with a certain action.

```js
function shouldUpdateUrl(url, expectedUrl) {
    return url !== expectedUrl;
}
```

### `min`/`max`

Represents a minimum or maximum value. Used when describing boundaries or limits.

```js
/**
 * Renders a random amount of posts within
 * the given min/max boundaries.
 */
function renderPosts(posts, minPosts, maxPosts) {
    return posts.slice(0, randomBetween(minPosts, maxPosts));
}
```

### `prev`/`next`

Indicate the previous or the next state of a variable in the current context. Used when describing state transitions.

```jsx
function fetchPosts() {
    const prevPosts = this.state.posts;

    const fetchedPosts = fetch('...');
    const nextPosts = concat(prevPosts, fetchedPosts);

    this.setState({ posts: nextPosts });
}
```

## Singular and Plurals

Like a prefix, variable names can be made singular or plural depending on whether they hold a single value or multiple values.

```js
/* Bad */
const friends = 'Bob';
const friend = ['Bob', 'Tony', 'Tanya'];

/* Good */
const friend = 'Bob';
const friends = ['Bob', 'Tony', 'Tanya'];
```

## Resources

-   [Naming cheatsheet](https://github.com/kettanaito/naming-cheatsheet/blob/master/README.md)
-   [Effective Dart: Design](https://dart.dev/guides/language/effective-dart/design).
