---
title: Custom MSBuild Tasks
description: How to write custom MSBuild tasks in C#
date: 2025-10-08
topics:
- msbuild
- dotnet
- csharp
---

There are three ways to write a custom MSBuild task:

1. A .NET assembly
1. Inline inside a `.tasks` file
1. In a C# file imported inside a `.tasks` file

## Variations

### .NET Assembly

**A basic C# task:**

```c#
using Microsoft.Build.Framework;

using Task = Microsoft.Build.Utilities.Task;

namespace MyTask.MSBuild;

public sealed class HelloTask : Task
{
    [Required]
    public string? Name { get; set; }

    /// <inheritdoc />
    public override bool Execute()
    {
        this.Log.LogMessage(MessageImportance.High, $"Hello, {this.Name}!");
        return true;
    }
}
```

**The .csproj file:**

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Build.Utilities.Core" Version="17.14.8" />
  </ItemGroup>

</Project>
```

Then build the project.

Now, you can **import and use it**:

```xml
<Project>

  <UsingTask TaskName="MyTask.MSBuild.HelloTask"
             AssemblyFile="PATH_TO_YOUR_TASK_DLL"
             />

  <Target Name="_RunCustomTask" AfterTargets="Build">
    <HelloTask Name="World" />
  </Target>

</Project>
```

> [!WARNING]
> Once Visual Studio has processed the `<UsingTask>` element, the **dll is permanently loaded** in Visual Studio. Because of this, you **can't change the implementation** of the task - until you restart Visual Studio.

### Inline

**Define the task in a `.tasks` file:**

```xml
<Project>

  <UsingTask TaskName="HelloTask"
             TaskFactory="RoslynCodeTaskFactory"
             AssemblyFile="$(MSBuildToolsPath)\Microsoft.Build.Tasks.Core.dll">
    <ParameterGroup>
      <Name ParameterType="System.String" Required="true" />
    </ParameterGroup>
    <Task>
      <Using Namespace="System" />
      <Code Type="Fragment" Language="cs">
        <![CDATA[
          Log.LogMessage(MessageImportance.High, $"Hello, {Name}!");
        ]]>
      </Code>
    </Task>
  </UsingTask>

</Project>
```

**Use it:**

```xml
<Project>

  <Import Project="$(MSBuildThisFileDirectory)MyTask.tasks" />

  <Target Name="_RunCustomTask" AfterTargets="Build">
    <HelloTask Name="World" />
  </Target>

</Project>
```

### Inline with C# File

This is a variation of the inline definition.

**Define the task in a C# file:**

```csharp
using Microsoft.Build.Framework;

using Task = Microsoft.Build.Utilities.Task;

namespace TarTask.MSBuild;

#nullable enable

public sealed class HelloTask : Task
{
    [Required]
    public string? Name { get; set; }

    /// <inheritdoc />
    public override bool Execute()
    {
        this.Log.LogMessage(MessageImportance.High, $"Hello, {this.Name}!");
        return true;
    }
}
```

**Import and use the task:**

```xml
<Project>

  <UsingTask TaskName="HelloTask"
             TaskFactory="RoslynCodeTaskFactory"
             AssemblyFile="$(MSBuildToolsPath)\Microsoft.Build.Tasks.Core.dll">
    <ParameterGroup>
      <Name ParameterType="System.String" Required="true" />
    </ParameterGroup>
    <Task>
      <Using Namespace="System" />
      <Code Type="Class" Language="cs" Source="$(MSBuildThisFileDirectory)HelloTask.cs" />
    </Task>
  </UsingTask>

  <!-- Make VS rebuild project when task has changed. -->
  <ItemGroup>
    <UpToDateCheckInput Include="$(MSBuildThisFileDirectory)HelloTask.cs" />
  </ItemGroup>

  <Target Name="_RunCustomTask" AfterTargets="Build">
    <HelloTask Name="World" />
  </Target>

</Project>
```

## Comparison

This how these approaches differ:

| What                          | Assembly                  | Inline | Inline with C# File
| ----------------------------- | ------------------------- | ------ | -------------------
| Change Implementation         | ❌ (requires VS restart)  | ✅    | ✅
| Code Completion               | ✅                        | ❌    | ❌
| C# Syntax Highlighting        | ✅                        | ✅    | ❌
| More than one file possible   | ✅                        | ❌    | ❌
