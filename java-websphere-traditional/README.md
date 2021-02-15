# Java tWAS Stack

The Java WebSphere Traditional stack provides a consistent way of developing tWAS apps. This stack lets you use [Maven](https://maven.apache.org) to develop applications for the tWAS runtime, that is running on OpenJDK with container-optimizations in OpenJ9.

The Java WebSphere Traditional stack uses a parent Maven project object model (POM) to manage dependency versions and provide required capabilities and plugins.

This stack is based on OpenJDK with container-optimizations in OpenJ9.

**Note:** Maven is provided by the Appsody stack container, allowing you to build, test, and debug your Java application without installing Maven locally. However, we recommend installing Maven locally for the best IDE experience.

## Templates

Templates are used to create your local project and start your development. When initializing your project you will be provided with a tWAS template application.

The default template provides a `pom.xml` file that references the parent POM defined by the stack.

## Getting Started

1. Create a new folder in your local directory and initialize it using the Appsody CLI, e.g.:
    ```bash
    mkdir my-project
    cd my-project
    appsody init java-websphere-traditional
    ```

    This will initialize a Java tWAS project using the default template. This will also install all parent pom dependencies into your local .m2 directory.

1. Once your project has been initialized, you can run your application using the following command:

    ```bash
    appsody run
    ```

    This launches a Docker container that starts your application in the foreground, exposing it on port 9080.

    You can continue to edit the application in your preferred IDE (Eclipse, VSCode or others) and your changes will be reflected in the running container within a few seconds.

## License

This stack is licensed under the [Apache 2.0](./image/LICENSE) license
