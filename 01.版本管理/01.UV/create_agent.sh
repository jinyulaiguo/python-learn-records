#!/bin/bash

# ==============================================================================
# 工具名称: 现代 Python AI Agent 生产级项目生成器
# 依赖环境: uv (https://github.com/astral-sh/uv)
# ==============================================================================

# --- 1. 参数解析与默认值设定 ---
# $1: 第一个参数，作为项目文件夹的名称。默认值为 "my-ai-agent"
PROJECT_DIR=${1:-my-ai-agent}

# $2: 第二个参数，作为 Python 内部的包名。
# 黑魔法解析：如果传入了 $2，则使用 $2；如果未传入，则自动将 PROJECT_DIR 中的连字符(-)全局替换为下划线(_)
PACKAGE_NAME=${2:-${PROJECT_DIR//-/_}}

echo "🚀 [1/4] 启动工程引擎..."
echo "📂 项目目录: $PROJECT_DIR"
echo "📦 内部包名: $PACKAGE_NAME"
echo "------------------------------------------------"

# --- 2. 环境前置检查 ---
if ! command -v uv &> /dev/null; then
    echo "❌ 严重错误: 未检测到现代构建工具 uv。"
    echo "💡 修复方法: 请执行 curl -LsSf https://astral.sh/uv/install.sh | sh 安装"
    exit 1
fi

# --- 3. 初始化基础环境 ---
# 使用 uv 初始化应用级项目（生成 pyproject.toml 和虚拟环境）
uv init --app "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit

echo "⚙️ [2/4] uv 基础环境就绪，开始注入 src-layout 目录骨架与样板代码..."

# --- 4. 动态生成 Python 脚本进行深度定制 (Heredoc 技术) ---
cat << EOF > .tmp_scaffold.py
import sys
from pathlib import Path

# 从 Bash 环境变量/注入中获取包名
PACKAGE_NAME = "$PACKAGE_NAME"

# 定义生产级目录结构
DIRECTORIES = [
    f"src/{{PACKAGE_NAME}}/api/routes",
    f"src/{{PACKAGE_NAME}}/core",
    f"src/{{PACKAGE_NAME}}/agents",
    f"src/{{PACKAGE_NAME}}/services",
    f"src/{{PACKAGE_NAME}}/models",
    f"src/{{PACKAGE_NAME}}/utils",
    "tests/test_api",
    "tests/test_agents",
]

# 定义核心初始文件与样板代码
FILES_WITH_CONTENT = {
    ".env": "DEEPSEEK_API_KEY=your_api_key_here\\n",
    ".env.example": "DEEPSEEK_API_KEY=\\n",
    f"src/{{PACKAGE_NAME}}/__init__.py": "",
    
    # 核心配置 (Pydantic Settings)
    f"src/{{PACKAGE_NAME}}/core/config.py": f\"\"\"from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    project_name: str = "DeepSeek AI Agent Service"
    deepseek_api_key: str = ""
    deepseek_api_base: str = "https://api.deepseek.com/v1"
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
\"\"\",
    f"src/{{PACKAGE_NAME}}/core/exceptions.py": "# 全局异常定义\\n",
    f"src/{{PACKAGE_NAME}}/core/__init__.py": "",

    # API 路由骨架
    f"src/{{PACKAGE_NAME}}/api/dependencies.py": "# FastAPI 依赖注入\\n",
    f"src/{{PACKAGE_NAME}}/api/routes/chat.py": "# 对话路由\\n",
    f"src/{{PACKAGE_NAME}}/api/routes/__init__.py": "",
    f"src/{{PACKAGE_NAME}}/api/__init__.py": "",

    # AI Agent 核心逻辑层
    f"src/{{PACKAGE_NAME}}/agents/llm.py": f\"\"\"from langchain_openai import ChatOpenAI
from {{PACKAGE_NAME}}.core.config import settings

def get_deepseek_llm(temperature: float = 0.7):
    return ChatOpenAI(
        model="deepseek-chat",
        api_key=settings.deepseek_api_key,
        base_url=settings.deepseek_api_base,
        max_tokens=4096,
        temperature=temperature
    )
\"\"\",
    f"src/{{PACKAGE_NAME}}/agents/state.py": "from typing import TypedDict, Annotated\\nimport operator\\n\\nclass AgentState(TypedDict):\\n    messages: Annotated[list, operator.add]\\n",
    f"src/{{PACKAGE_NAME}}/agents/nodes.py": "# Graph 节点定义: 处理具体业务逻辑\\n",
    f"src/{{PACKAGE_NAME}}/agents/tools.py": "# Tools 定义: 提供给大模型的外部函数调用\\n",
    f"src/{{PACKAGE_NAME}}/agents/graph.py": "# Graph 编排: 定义节点流转边与条件路由\\n",
    f"src/{{PACKAGE_NAME}}/agents/__init__.py": "",

    # 其他标准分层
    f"src/{{PACKAGE_NAME}}/services/user_service.py": "",
    f"src/{{PACKAGE_NAME}}/services/__init__.py": "",
    f"src/{{PACKAGE_NAME}}/models/domain.py": "# 数据库模型 (SQLAlchemy / SQLModel)\\n",
    f"src/{{PACKAGE_NAME}}/models/schemas.py": "# API 数据验证模型 (Pydantic)\\n",
    f"src/{{PACKAGE_NAME}}/models/__init__.py": "",
    f"src/{{PACKAGE_NAME}}/utils/logger.py": "# 结构化日志配置\\n",
    f"src/{{PACKAGE_NAME}}/utils/__init__.py": "",
    
    # 测试目录
    "tests/conftest.py": "# Pytest 全局 fixtures\\n",
    "tests/__init__.py": "",
}

# 执行创建逻辑
for dir_path in DIRECTORIES:
    Path(dir_path).mkdir(parents=True, exist_ok=True)

for file_path, content in FILES_WITH_CONTENT.items():
    path = Path(file_path)
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
EOF

# 执行动态生成的构建脚本
uv run .tmp_scaffold.py

# 安全清理临时文件
rm .tmp_scaffold.py

echo "🧱 [3/4] 骨架搭建完成。开始锁定并安装核心依赖..."

# --- 5. 安装必需的业务依赖 ---
uv add pydantic-settings langchain-openai

echo "✅ [4/4] 项目构建完毕！"
echo "==============================================="
echo "👉 开始开发命令:"
echo "   cd $PROJECT_DIR"
echo "   uv run python -c \"import $PACKAGE_NAME\"  # 测试包导入是否成功"
echo "==============================================="