Absolutely. Here’s an **OpenAPI-like** spec in **YAML** (easy to read and extend) saved under `knowledge_base/docs/`. It’s derived from the schema-accurate shapes we captured so far, and it includes clear `TODO` placeholders for the endpoint modules we haven’t enumerated yet (Memory/Voice/Terminal/BMAD + any additional ProjectApi routes).

```yaml
openapi: 3.0.3
info:
  title: AiderDesk REST API (OpenAPI-like)
  version: 0.1.0
  description: |
    OpenAPI-like specification generated from server-side request validation.
    This is intended as a pragmatic contract for building external clients.

    Notes:
    - Base path is mounted at /api
    - Basic Auth may be required depending on server settings or env overrides.
    - Some modules are registered but not yet enumerated here:
      MemoryApi, VoiceApi, TerminalApi, BmadApi
servers:
  - url: http://localhost:24337/api

security:
  - basicAuth: []

tags:
  - name: settings
  - name: prompts
  - name: context
  - name: projects
  - name: tasks
  - name: commands
  - name: todo
  - name: providers
  - name: agents
  - name: mcp
  - name: system
  - name: usage
  - name: worktree
  - name: TODO

components:
  securitySchemes:
    basicAuth:
      type: http
      scheme: basic

  schemas:
    # Generic error shape (actual server errors may vary)
    ErrorResponse:
      type: object
      properties:
        error:
          type: string

    MessageResponse:
      type: object
      properties:
        message:
          type: string

    ProjectDir:
      type: string
      minLength: 1
      description: Absolute path to a project directory on the machine running AiderDesk.

    TaskId:
      type: string
      minLength: 1

    MessageId:
      type: string
      minLength: 1

    Mode:
      type: string
      enum: [agent, code, ask, architect, context]

    SettingsObject:
      description: Settings object (structure is implementation-defined).
      type: object
      additionalProperties: true

    ProviderProfiles:
      type: array
      items: {}
      description: Provider profiles; currently validated as any.

    RunPromptRequest:
      type: object
      required: [projectDir, taskId, prompt]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        prompt:
          type: string
          minLength: 1
        mode:
          $ref: "#/components/schemas/Mode"

    SavePromptRequest:
      type: object
      required: [projectDir, taskId, prompt]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        prompt:
          type: string
          minLength: 1

    AddContextFileRequest:
      type: object
      required: [projectDir, taskId, path]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        path:
          type: string
          minLength: 1
        readOnly:
          type: boolean

    DropContextFileRequest:
      type: object
      required: [projectDir, taskId, path]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        path:
          type: string
          minLength: 1

    GetContextFilesRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    GetAddableFilesRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        searchRegex:
          type: string

    GetAllFilesRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        useGit:
          type: boolean

    CreateTaskRequest:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        parentId:
          description: Parent task ID (nullable/optional)
          type: string
          nullable: true
        name:
          type: string

    UpdateTaskRequest:
      type: object
      required: [projectDir, id, updates]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        id:
          $ref: "#/components/schemas/TaskId"
        updates:
          description: Partial TaskData (from shared types). Not expanded here.
          type: object
          additionalProperties: true

    LoadTaskRequest:
      type: object
      required: [projectDir, id]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        id:
          $ref: "#/components/schemas/TaskId"

    DeleteTaskRequest:
      type: object
      required: [projectDir, id]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        id:
          $ref: "#/components/schemas/TaskId"

    DuplicateTaskRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    ForkTaskRequest:
      type: object
      required: [projectDir, taskId, messageId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        messageId:
          $ref: "#/components/schemas/MessageId"

    ResetTaskRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    ExportMarkdownRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    RemoveLastMessageRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    RemoveMessageRequest:
      type: object
      required: [projectDir, taskId, messageId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        messageId:
          $ref: "#/components/schemas/MessageId"

    CompactConversationRequest:
      type: object
      required: [projectDir, taskId, mode]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        mode:
          $ref: "#/components/schemas/Mode"
        customInstructions:
          type: string

    HandoffConversationRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        focus:
          type: string

    InterruptRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    ClearContextRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    AnswerQuestionRequest:
      type: object
      required: [projectDir, taskId, answer]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        answer:
          type: string
          minLength: 1

    AddOpenProjectRequest:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"

    RemoveOpenProjectRequest:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"

    SetActiveProjectRequest:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"

    UpdateOpenProjectsOrderRequest:
      type: object
      required: [projectDirs]
      properties:
        projectDirs:
          type: array
          items:
            type: string
            minLength: 1

    RestartProjectRequest:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"

    StartStopProjectRequest:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"

    ValidatePathRequest:
      type: object
      required: [projectDir, path]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        path:
          type: string
          minLength: 1

    IsProjectPathRequest:
      type: object
      required: [path]
      properties:
        path:
          type: string
          minLength: 1

    FileSuggestionsRequest:
      type: object
      required: [currentPath]
      properties:
        currentPath:
          type: string
          minLength: 1
        directoriesOnly:
          type: boolean

    PasteImageRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        base64ImageData:
          type: string

    ApplyEditsRequest:
      type: object
      required: [projectDir, taskId, edits]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        edits:
          type: array
          items:
            type: object
            required: [path, original, updated]
            properties:
              path:
                type: string
              original:
                type: string
              updated:
                type: string

    RunCommandRequest:
      type: object
      required: [projectDir, taskId, command]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        command:
          type: string
          minLength: 1

    InitRulesRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    ScrapeWebRequest:
      type: object
      required: [projectDir, taskId, url]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        url:
          type: string
          format: uri
          minLength: 1
        filePath:
          type: string

    RedoPromptRequest:
      type: object
      required: [projectDir, taskId, mode]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        mode:
          $ref: "#/components/schemas/Mode"
        updatedPrompt:
          type: string

    ResumeTaskRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    EditFormatsUpdateRequest:
      type: object
      required: [projectDir, editFormats]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        editFormats:
          type: object
          additionalProperties:
            type: string
            enum: [diff, diff-fenced, whole, udiff, udiff-simple, patch]

    UpdateMainModelRequest:
      type: object
      required: [projectDir, taskId, mainModel]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        mainModel:
          type: string
          minLength: 1

    UpdateWeakModelRequest:
      type: object
      required: [projectDir, taskId, weakModel]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        weakModel:
          type: string
          minLength: 1

    UpdateArchitectModelRequest:
      type: object
      required: [projectDir, taskId, architectModel]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        architectModel:
          type: string
          minLength: 1

    WorktreeMergeToMainRequest:
      type: object
      required: [projectDir, taskId, squash]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        squash:
          type: boolean
        targetBranch:
          type: string
        commitMessage:
          type: string

    WorktreeApplyUncommittedRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        targetBranch:
          type: string

    WorktreeRebaseFromBranchRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        fromBranch:
          type: string

    WorktreeBasicRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    QueryUsageRequest:
      type: object
      required: [from, to]
      properties:
        from:
          type: string
          minLength: 1
        to:
          type: string
          minLength: 1

    EnvVarResponse:
      type: object
      additionalProperties: true

    GetEnvVarQuery:
      type: object
      required: [key]
      properties:
        key:
          type: string
          minLength: 1
        baseDir:
          type: string

    CustomCommandsQuery:
      type: object
      required: [projectDir]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"

    RunCustomCommandRequest:
      type: object
      required: [projectDir, taskId, commandName, args, mode]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        commandName:
          type: string
          minLength: 1
        args:
          type: array
          items:
            type: string
        mode:
          type: string
          enum: [code, ask, architect, context, agent]

    TodoQuery:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    TodoAddRequest:
      type: object
      required: [projectDir, taskId, name]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        name:
          type: string
          minLength: 1

    TodoUpdateRequest:
      type: object
      required: [projectDir, taskId, name, updates]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        name:
          type: string
          minLength: 1
        updates:
          type: object
          properties:
            name:
              type: string
            completed:
              type: boolean
          additionalProperties: false

    TodoDeleteRequest:
      type: object
      required: [projectDir, taskId, name]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"
        name:
          type: string
          minLength: 1

    TodoClearRequest:
      type: object
      required: [projectDir, taskId]
      properties:
        projectDir:
          $ref: "#/components/schemas/ProjectDir"
        taskId:
          $ref: "#/components/schemas/TaskId"

    McpToolsRequest:
      type: object
      required: [serverName]
      properties:
        serverName:
          type: string
          minLength: 1
        config:
          type: object
          properties:
            command:
              type: string
            args:
              type: array
              items: { type: string }
            env:
              type: object
              additionalProperties: { type: string }
            url:
              type: string
            headers:
              type: object
              additionalProperties: { type: string }
          additionalProperties: false

    McpReloadRequest:
      type: object
      required: [mcpServers]
      properties:
        mcpServers:
          type: object
          additionalProperties:
            type: object
            properties:
              command: { type: string }
              args:
                type: array
                items: { type: string }
              env:
                type: object
                additionalProperties: { type: string }
              url: { type: string }
              headers:
                type: object
                additionalProperties: { type: string }
            additionalProperties: false
        force:
          type: boolean

    AgentProfileCreateRequest:
      type: object
      required: [profile]
      properties:
        profile: {}
        projectDir:
          type: string

    AgentProfileUpdateRequest:
      type: object
      required: [profile]
      properties:
        profile: {}
        baseDir:
          type: string

    AgentProfileDeleteRequest:
      type: object
      required: [profileId]
      properties:
        profileId:
          type: string
          minLength: 1
        baseDir:
          type: string

    AgentProfilesOrderRequest:
      type: object
      required: [agentProfiles]
      properties:
        agentProfiles:
          type: array
          items: {}

    ProvidersPutModelsRequest:
      type: array
      items:
        type: object
        required: [providerId, modelId, model]
        properties:
          providerId:
            type: string
          modelId:
            type: string
          model: {}

paths:
  /settings:
    get:
      tags: [settings]
      summary: Get settings (also acts as health check)
      responses:
        "200":
          description: Settings object
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SettingsObject"
        "401":
          description: Authentication required/invalid
        "503":
          description: Server not started
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ErrorResponse"
    post:
      tags: [settings]
      summary: Update settings
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/SettingsObject"
      responses:
        "200":
          description: Updated settings
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/SettingsObject"

  /settings/recent-projects:
    get:
      tags: [settings]
      summary: Get recent projects
      responses:
        "200":
          description: Recent projects
          content:
            application/json:
              schema: {}

  /settings/add-recent-project:
    post:
      tags: [settings]
      summary: Add recent project
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [projectDir]
              properties:
                projectDir:
                  $ref: "#/components/schemas/ProjectDir"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /settings/remove-recent-project:
    post:
      tags: [settings]
      summary: Remove recent project
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [projectDir]
              properties:
                projectDir:
                  $ref: "#/components/schemas/ProjectDir"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /settings/zoom:
    post:
      tags: [settings]
      summary: Set zoom level
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [level]
              properties:
                level:
                  type: number
                  minimum: 0.5
                  maximum: 3.0
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /versions:
    get:
      tags: [settings]
      summary: Get versions
      parameters:
        - in: query
          name: forceRefresh
          schema:
            type: string
          required: false
      responses:
        "200":
          description: Versions payload
          content:
            application/json:
              schema: {}

  /download-latest:
    post:
      tags: [settings]
      summary: Download latest AiderDesk
      requestBody:
        required: false
        content:
          application/json:
            schema:
              type: object
              additionalProperties: false
      responses:
        "200":
          description: Download started
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /release-notes:
    get:
      tags: [settings]
      summary: Get release notes
      responses:
        "200":
          description: Release notes
          content:
            application/json:
              schema:
                type: object
                properties:
                  releaseNotes: {}

  /clear-release-notes:
    post:
      tags: [settings]
      summary: Clear release notes
      requestBody:
        required: false
        content:
          application/json:
            schema:
              type: object
              additionalProperties: false
      responses:
        "200":
          description: Cleared
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /os:
    get:
      tags: [settings]
      summary: Get OS
      responses:
        "200":
          description: OS info
          content:
            application/json:
              schema:
                type: object
                properties:
                  os: {}

  /run-prompt:
    post:
      tags: [prompts]
      summary: Run a prompt on a task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RunPromptRequest"
      responses:
        "200":
          description: Responses payload
          content:
            application/json:
              schema: {}

  /save-prompt:
    post:
      tags: [prompts]
      summary: Save a prompt
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/SavePromptRequest"
      responses:
        "200":
          description: Saved
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /add-context-file:
    post:
      tags: [context]
      summary: Add a file to task context
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/AddContextFileRequest"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /drop-context-file:
    post:
      tags: [context]
      summary: Drop a file from task context
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/DropContextFileRequest"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /get-context-files:
    post:
      tags: [context]
      summary: Get context files for a task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/GetContextFilesRequest"
      responses:
        "200":
          description: Context files list
          content:
            application/json:
              schema: {}

  /get-addable-files:
    post:
      tags: [context]
      summary: Get addable files for a task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/GetAddableFilesRequest"
      responses:
        "200":
          description: Addable files list
          content:
            application/json:
              schema: {}

  /get-all-files:
    post:
      tags: [context]
      summary: Get all files for a task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/GetAllFilesRequest"
      responses:
        "200":
          description: All files list
          content:
            application/json:
              schema: {}

  /project/custom-commands:
    get:
      tags: [commands]
      summary: List custom commands for a project
      parameters:
        - in: query
          name: projectDir
          required: true
          schema:
            $ref: "#/components/schemas/ProjectDir"
      responses:
        "200":
          description: Commands list
          content:
            application/json:
              schema: {}
    post:
      tags: [commands]
      summary: Run a custom command
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RunCustomCommandRequest"
      responses:
        "200":
          description: Executed
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /usage:
    get:
      tags: [usage]
      summary: Query usage data
      parameters:
        - in: query
          name: from
          required: true
          schema:
            type: string
            minLength: 1
        - in: query
          name: to
          required: true
          schema:
            type: string
            minLength: 1
      responses:
        "200":
          description: Usage data
          content:
            application/json:
              schema: {}

  /system/env-var:
    get:
      tags: [system]
      summary: Get effective environment variable
      parameters:
        - in: query
          name: key
          required: true
          schema:
            type: string
            minLength: 1
        - in: query
          name: baseDir
          required: false
          schema:
            type: string
      responses:
        "200":
          description: Environment variable payload
          content:
            application/json:
              schema: {}

  /project/todos:
    get:
      tags: [todo]
      summary: Get todos for a task
      parameters:
        - in: query
          name: projectDir
          required: true
          schema:
            $ref: "#/components/schemas/ProjectDir"
        - in: query
          name: taskId
          required: true
          schema:
            $ref: "#/components/schemas/TaskId"
      responses:
        "200":
          description: Todos list
          content:
            application/json:
              schema: {}

  /project/todo/add:
    post:
      tags: [todo]
      summary: Add todo
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/TodoAddRequest"
      responses:
        "200":
          description: Updated todos
          content:
            application/json:
              schema: {}

  /project/todo/update:
    patch:
      tags: [todo]
      summary: Update todo
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/TodoUpdateRequest"
      responses:
        "200":
          description: Updated todos
          content:
            application/json:
              schema: {}

  /project/todo/delete:
    post:
      tags: [todo]
      summary: Delete todo
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/TodoDeleteRequest"
      responses:
        "200":
          description: Updated todos
          content:
            application/json:
              schema: {}

  /project/todo/clear:
    post:
      tags: [todo]
      summary: Clear all todos
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/TodoClearRequest"
      responses:
        "200":
          description: Updated todos
          content:
            application/json:
              schema: {}

  /mcp/tools:
    post:
      tags: [mcp]
      summary: Load MCP server tools
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/McpToolsRequest"
      responses:
        "200":
          description: Tools list
          content:
            application/json:
              schema: {}

  /mcp/reload:
    post:
      tags: [mcp]
      summary: Reload MCP servers
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/McpReloadRequest"
      responses:
        "200":
          description: Reload initiated
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /providers:
    get:
      tags: [providers]
      summary: Get providers
      responses:
        "200":
          description: Providers list
          content:
            application/json:
              schema: {}
    post:
      tags: [providers]
      summary: Update providers
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ProviderProfiles"
      responses:
        "200":
          description: Updated
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /models:
    get:
      tags: [providers]
      summary: Get provider models
      parameters:
        - in: query
          name: reload
          required: false
          schema:
            type: string
            description: Set to "true" to reload models.
      responses:
        "200":
          description: Models
          content:
            application/json:
              schema: {}
    put:
      tags: [providers]
      summary: Bulk update models
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ProvidersPutModelsRequest"
      responses:
        "200":
          description: Models after update
          content:
            application/json:
              schema: {}

  /providers/{providerId}/models:
    put:
      tags: [providers]
      summary: Upsert a single model
      parameters:
        - in: path
          name: providerId
          required: true
          schema:
            type: string
        - in: query
          name: modelId
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema: {}
      responses:
        "200":
          description: Models after upsert
          content:
            application/json:
              schema: {}
    delete:
      tags: [providers]
      summary: Delete a model
      parameters:
        - in: path
          name: providerId
          required: true
          schema:
            type: string
        - in: query
          name: modelId
          required: true
          schema:
            type: string
      responses:
        "200":
          description: Models after delete
          content:
            application/json:
              schema: {}

  /agent-profiles:
    get:
      tags: [agents]
      summary: List agent profiles
      responses:
        "200":
          description: Profiles
          content:
            application/json:
              schema: {}

  /agent-profile/create:
    post:
      tags: [agents]
      summary: Create agent profile
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/AgentProfileCreateRequest"
      responses:
        "200":
          description: Profiles
          content:
            application/json:
              schema: {}

  /agent-profile/update:
    post:
      tags: [agents]
      summary: Update agent profile
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/AgentProfileUpdateRequest"
      responses:
        "200":
          description: Profiles
          content:
            application/json:
              schema: {}

  /agent-profile/delete:
    post:
      tags: [agents]
      summary: Delete agent profile
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/AgentProfileDeleteRequest"
      responses:
        "200":
          description: Profiles
          content:
            application/json:
              schema: {}

  /agent-profiles/order:
    post:
      tags: [agents]
      summary: Update agent profiles order
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/AgentProfilesOrderRequest"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema: { type: object, properties: { success: { type: boolean } } }

  /projects:
    get:
      tags: [projects]
      summary: Get open projects
      responses:
        "200":
          description: Projects list
          content:
            application/json:
              schema: {}

  /project/input-history:
    get:
      tags: [projects]
      summary: Get input history
      parameters:
        - in: query
          name: projectDir
          required: true
          schema:
            $ref: "#/components/schemas/ProjectDir"
      responses:
        "200":
          description: Input history
          content:
            application/json:
              schema: {}

  /project/redo-prompt:
    post:
      tags: [projects]
      summary: Redo last user prompt
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RedoPromptRequest"
      responses:
        "200":
          description: Initiated
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/resume-task:
    post:
      tags: [projects]
      summary: Resume task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ResumeTaskRequest"
      responses:
        "200":
          description: Resumed
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/validate-path:
    post:
      tags: [projects]
      summary: Validate path
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ValidatePathRequest"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  isValid:
                    type: boolean

  /project/is-project-path:
    post:
      tags: [projects]
      summary: Check if path is a project path
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/IsProjectPathRequest"
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                type: object
                properties:
                  isProject:
                    type: boolean

  /project/file-suggestions:
    post:
      tags: [projects]
      summary: Get file path suggestions
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/FileSuggestionsRequest"
      responses:
        "200":
          description: Suggestions
          content:
            application/json:
              schema: {}

  /project/paste-image:
    post:
      tags: [projects]
      summary: Paste image to task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/PasteImageRequest"
      responses:
        "200":
          description: Pasted
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/apply-edits:
    post:
      tags: [projects]
      summary: Apply edits
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ApplyEditsRequest"
      responses:
        "200":
          description: Applied
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/run-command:
    post:
      tags: [projects]
      summary: Run command
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RunCommandRequest"
      responses:
        "200":
          description: Executed
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/init-rules:
    post:
      tags: [projects]
      summary: Initialize project rules
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/InitRulesRequest"
      responses:
        "200":
          description: Initialized
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/tasks/new:
    post:
      tags: [tasks]
      summary: Create new task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateTaskRequest"
      responses:
        "200":
          description: Task created
          content:
            application/json:
              schema: {}

  /project/tasks:
    get:
      tags: [tasks]
      summary: List tasks
      parameters:
        - in: query
          name: projectDir
          required: true
          schema:
            $ref: "#/components/schemas/ProjectDir"
      responses:
        "200":
          description: Tasks
          content:
            application/json:
              schema: {}
    post:
      tags: [tasks]
      summary: Update/save task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/UpdateTaskRequest"
      responses:
        "200":
          description: Saved task
          content:
            application/json:
              schema: {}

  /project/tasks/load:
    post:
      tags: [tasks]
      summary: Load task (messages/context)
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/LoadTaskRequest"
      responses:
        "200":
          description: Task context data
          content:
            application/json:
              schema: {}

  /project/tasks/delete:
    post:
      tags: [tasks]
      summary: Delete task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/DeleteTaskRequest"
      responses:
        "200":
          description: Deleted
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/tasks/duplicate:
    post:
      tags: [tasks]
      summary: Duplicate task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/DuplicateTaskRequest"
      responses:
        "200":
          description: Duplicated task
          content:
            application/json:
              schema: {}

  /project/tasks/fork:
    post:
      tags: [tasks]
      summary: Fork task from message
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ForkTaskRequest"
      responses:
        "200":
          description: Forked task
          content:
            application/json:
              schema: {}

  /project/tasks/reset:
    post:
      tags: [tasks]
      summary: Reset task
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ResetTaskRequest"
      responses:
        "200":
          description: Reset
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/tasks/export-markdown:
    post:
      tags: [tasks]
      summary: Export session to markdown
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ExportMarkdownRequest"
      responses:
        "200":
          description: Markdown content
          content:
            text/markdown:
              schema:
                type: string

  /project/remove-last-message:
    post:
      tags: [tasks]
      summary: Remove last message
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RemoveLastMessageRequest"
      responses:
        "200":
          description: Removed
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/remove-message:
    delete:
      tags: [tasks]
      summary: Remove message by id
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RemoveMessageRequest"
      responses:
        "200":
          description: Removed
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/remove-messages-up-to:
    delete:
      tags: [tasks]
      summary: Remove messages up to messageId
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/RemoveMessageRequest"
      responses:
        "200":
          description: Removed
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/compact-conversation:
    post:
      tags: [tasks]
      summary: Compact conversation
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CompactConversationRequest"
      responses:
        "200":
          description: Compacted
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/handoff-conversation:
    post:
      tags: [tasks]
      summary: Handoff conversation
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/HandoffConversationRequest"
      responses:
        "200":
          description: Handed off
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/interrupt:
    post:
      tags: [tasks]
      summary: Interrupt response
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/InterruptRequest"
      responses:
        "200":
          description: Interrupt sent
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/clear-context:
    post:
      tags: [tasks]
      summary: Clear context
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ClearContextRequest"
      responses:
        "200":
          description: Cleared
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/answer-question:
    post:
      tags: [tasks]
      summary: Answer question
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/AnswerQuestionRequest"
      responses:
        "200":
          description: Answer submitted
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/scrape-web:
    post:
      tags: [projects]
      summary: Scrape web content into context
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/ScrapeWebRequest"
      responses:
        "200":
          description: Scraped
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/merge-to-main:
    post:
      tags: [worktree]
      summary: Merge worktree to main
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeMergeToMainRequest"
      responses:
        "200":
          description: Merged
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/apply-uncommitted:
    post:
      tags: [worktree]
      summary: Apply uncommitted changes
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeApplyUncommittedRequest"
      responses:
        "200":
          description: Applied
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/revert-last-merge:
    post:
      tags: [worktree]
      summary: Revert last merge
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeBasicRequest"
      responses:
        "200":
          description: Reverted
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/branches:
    get:
      tags: [worktree]
      summary: List branches
      parameters:
        - in: query
          name: projectDir
          required: true
          schema:
            $ref: "#/components/schemas/ProjectDir"
      responses:
        "200":
          description: Branches
          content:
            application/json:
              schema: {}

  /project/worktree/status:
    get:
      tags: [worktree]
      summary: Worktree status
      parameters:
        - in: query
          name: projectDir
          required: true
          schema:
            $ref: "#/components/schemas/ProjectDir"
        - in: query
          name: taskId
          required: true
          schema:
            $ref: "#/components/schemas/TaskId"
        - in: query
          name: targetBranch
          required: false
          schema:
            type: string
      responses:
        "200":
          description: Status
          content:
            application/json:
              schema: {}

  /project/worktree/rebase-from-branch:
    post:
      tags: [worktree]
      summary: Rebase worktree from branch
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeRebaseFromBranchRequest"
      responses:
        "200":
          description: Rebased
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/abort-rebase:
    post:
      tags: [worktree]
      summary: Abort rebase
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeBasicRequest"
      responses:
        "200":
          description: Aborted
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/continue-rebase:
    post:
      tags: [worktree]
      summary: Continue rebase
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeBasicRequest"
      responses:
        "200":
          description: Continued
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  /project/worktree/resolve-conflicts-with-agent:
    post:
      tags: [worktree]
      summary: Resolve conflicts with agent
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/WorktreeBasicRequest"
      responses:
        "200":
          description: Resolved
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/MessageResponse"

  # TODO endpoints: MemoryApi / VoiceApi / TerminalApi / BmadApi
  # Add once route definitions are extracted:
  # - /memory/...
  # - /voice/...
  # - /terminal/...
  # - /bmad/...
```


