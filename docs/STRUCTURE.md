# Application structure

This guide describes how to provide a consistent, moduler, well scaled structure, which makes it easier to increase developer efficiency by finding code quickly.
To confirm your intuition about a particular structure, ask: can I quickly open and start work in all of the related files for this feature?

## Workspace

We use NX rules to organize application code. Basic building blocks of Nx are: workspaces, apps and libs.

### What is a workspace?

A workspace is a folder created using Nx. The folder consists of a single git repository, with folders for apps (applications) and libs (libraries); along with some scaffolding to help with building, linting, and testing.

### What is an app?

The app defines how to build the artifacts that are shipped to the user.
Apps are meant only to organize other libs into a deployable artifact - there is not a lot of code present in the applications outside of the module file and maybe a some basic routing.
All of the application’s code is organized into libs.

### What is a lib?

The purpose of having libs is to partition your code into smaller units that are easier to maintain and promote code reuse.
Library is a collection of related files that perform a certain task. Libs are composed together to make up an application.
A typical Nx workspace contains only four types of libs: `feature`, `data-access`, `ui`, and `utils`.
You can read about these types of libraries in detail in Part 2 of the "Enterprise Angular Monorepo Patters" book.

# Organize code in library

In a small library, it's better to keep flat folder structure as long as possible.
Put folders for components, services, models and other additional stuff into root directory.

```
libs/
  feature-widget/
    src/
      lib/
        models/
          widget.model.ts
        settings/
          settings.component.ts
          settings.component.html
        services/
           widget.service.ts
        widget.component.ts
        widget.component.html
```

According to Angular Style Guide, creating sub-folders makes sense when a folder reaches seven or more files.
Put services, models and other additionals files and folders into `shared` directory.

```
libs/
  feature-widgets/
    src/
      lib/
        small/
          models/
            small-widget.model.ts
          settings/
            small-widget-settings.component.ts
            small-widget-settings.component.html
          services/
            small-widget.service.ts
          small-widget.component.ts
          small-widget.component.html
          small-widget.module.ts
        large
          +state/
            large-widget.reducer.ts
          header/
            search/
              header-search.component.ts
            toolbar/
              header-toolbar.component.ts
            header.component.ts
            header.component.html
          footer/
            footer.component.ts
          add-modal/
            add-modal.component.ts
          edit-modal/
            edit-modal.component.ts
          settings/
            settings.component.ts
          widget/
            controls/
              controls.component.ts
              controls.component.html
            list/
              list.component.ts
            content/
              content.component.ts
            large-widget.component.ts
            large-widget.component.html
          shared/
            models/
              large-widget.model.ts
            services/
              large-widget.service.ts
            validators/
            pipes/
          large-widget.module.ts
      feature-widgets.module.ts
```

Anyway, each case is individual. Base your decision on your comfort level.
Do not lock yourself to one structure, since it will change a lot depending on the feature.
The main goal is to be able to find files quickly.

## Resources

https://angular.io/guide/styleguide#application-structure-and-ngmodules
