# Styling Guideline

Follow [Scalable and Modular Architecture for CSS](http://smacss.com/) to write flexible and maintainable CSS code.
The core of SMACSS is categorization. There are five types of categories:

1. Base
2. Layout
3. Module
4. State
5. Theme

Each category has certain guidelines that apply to it.

**Base rules** are default rules for the entire application.
They might include tag selectors, pseudo-class selectors, child selectors or sibling selectors, etc.

Base rules should be defined in `/assets/scss/base.scss` file.

**Layout rules** divide the page into sections.
Usually there is only one element of this type on the page, so it
should be styled by ID selector, but can be used other where appropriate.

Layout rules should be defined in `/assets/scss/layout.scss` file.

**Modules** are the reusable, modular parts of our design.
They are the callouts, the sidebar sections, the product lists and so on.
When defining the rule set for a module, avoid using IDs and element selectors, sticking only to class names.
The main goal is to create flexible module which can be easily moved to different parts of the layout without breaking.

Angular component should define module and include all styles inside.

**State rules** are ways to describe how our modules or layouts will look when in a particular state.
There is a certain amount of state rules, such as _hidden_, _disabled_, _actived_, _hovered_, _expanded_ and so on.
Propose to skip _is_ prefix in state name, because a code is pretty understandable without it, but much clear.

It's better to keep state rules inside module.

**Theme rules** describe how modules or layouts might look.

It's better to keep theme rules inside module.

**Short summary:**

-   avoid using ID and element selectors because they are difficult to scale.
-   use semantic selectors, which describe what those elements mean and removed any ambiguity when it comes to styling them.
-   avoid using _!important_ flag, because it's difficult to overwrite such rule.
-   minimize the depth of selectors because such depth enforces dependency on a HTML structure.

**Properties ordering**

Organize and grouping properties from most important to least important in the following order:

1. Box
2. Border
3. Background
4. Text
5. Other

Box includes any property that affects the display and position of the box such as display, float, position, left, top, height, width and so on.
These are most important to me because they affect the flow of the rest of the document.

Border includes border, the often unused border-image, and border-radius.

Background, text and other are self descriptive.

**Naming**

Use following name convention in layout:

-   container (wrapper for elements, may include only display and position properties)
-   header
-   footer
-   content
-   sidebar

```html
<div class=container">
  <div class="header"></div>
  <div class="content">
    <div class="content-header-container">
        <-- long names might be a sign to move it to separate component -->
        <div class="content-header-label"></div>
        <div class="content-header-description"></div>
    </div>
  </div>
  <div class="sidebar"></div>
  <div class="footer"></div>
</div>
```

**Utility classes**

Use [Bootstrap v5](https://getbootstrap.com/docs/5.1/utilities/) utility classes wherever possible.

## CSS Variables vs SCSS Variables

**Prefer CSS custom properties (CSS variables) over SCSS variables** for values that:
- May change at runtime (themes, dark mode)
- Are used across component boundaries
- Represent design tokens (colors, spacing, typography)

```scss
// AVOID: SCSS variable - compiled away, not accessible at runtime
$border-color: #dee2e6;
$spacing-3: 12px;

.pane-body {
    padding: $spacing-3;
    border-top: solid 1px $border-color;
}

// PREFER: CSS variable - available at runtime, themeable
// Example: libs/dashboard/feature-widgets/.../widget-big-number-settings-item.component.scss
.pane-body {
    padding: var(--spacing-3);
    border-top: solid 1px var(--border-color);
}

.label {
    margin-top: var(--spacing-2);
    color: var(--body-color);
}
```

**When SCSS variables are still appropriate:**
- Build-time calculations (`$spacing * 2`)
- Sass maps and loops
- Values never changing at runtime (breakpoints)

**Reference Bootstrap CSS variables:** https://getbootstrap.com/docs/5.3/customize/css-variables/
