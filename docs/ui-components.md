# UI 组件注册表

> 本文件由 onePress 首次安装初始化，之后由 `/opsx:archive` 增量维护：每次归档把本次新建或改造的组件追加到对应分区，**只追加行，不重排、不删历史**。

## 使用说明

1. `/opsx:new` 起草 `ui-spec.md` 前 MUST 先检索本表，可复用的组件写入第 1 节复用表，不得重复造轮子。
2. 新增组件必须补齐：组件名称、路径、适用骨架 (Archetype)、核心 Props 签名。
3. 组件分级：`base`（无业务语义，如 DataTable）、`domain`（含业务语义，如 RoleBadge）。
4. `适用骨架` 列取值：`Dashboard-Grid` / `Master-Detail` / `Standard-CRUD-Table` / `Step-Wizard` / `Settings-Split`；通用组件填 `通用`。
5. 不收录纯布局容器与一次性页面片段。

## 基础组件（base）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|

## 业务组件（domain）

| 组件名称 | 路径 | 适用骨架 (Archetype) | 核心 Props 签名 |
|----------|------|----------------------|-----------------|
