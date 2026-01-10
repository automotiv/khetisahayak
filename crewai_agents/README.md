# Kheti Sahayak CrewAI Agents

This directory contains CrewAI agent definitions auto-generated from the `.claude/agents/` markdown files.

## Supported LLM Providers

| Provider | Models | Environment Variable |
|----------|--------|---------------------|
| **Anthropic (Claude)** | claude-sonnet-4-20250514, claude-opus-4, etc. | `ANTHROPIC_API_KEY` |
| **OpenAI** | gpt-4o, gpt-4-turbo, gpt-3.5-turbo | `OPENAI_API_KEY` |

## Requirements

- **Python 3.10+** (CrewAI requires Python 3.10 or higher)
- API key for your chosen provider

## Installation

```bash
# Install Python 3.11 via Homebrew (macOS)
brew install python@3.11

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Configuration

### Using Claude (Anthropic) - Default

```bash
export CREWAI_LLM_PROVIDER="anthropic"
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"  # optional, this is default
```

### Using OpenAI

```bash
export CREWAI_LLM_PROVIDER="openai"
export OPENAI_API_KEY="your-openai-api-key"
export OPENAI_MODEL="gpt-4o"  # optional, this is default
```

## Project Structure

```
crewai_agents/
├── agents/
│   ├── __init__.py
│   └── all_agents.py      # 112 auto-generated agent definitions
├── crews/
│   ├── __init__.py
│   ├── engineering_crew.py
│   ├── product_crew.py
│   ├── ml_crew.py
│   ├── qa_crew.py
│   ├── executive_crew.py
│   └── marketing_crew.py
├── config/
├── tools/
├── generate_agents.py     # Script to regenerate agents from .claude/agents/
├── main.py               # CLI entry point
├── requirements.txt
└── README.md
```

## Usage

### List All Agents

```bash
python main.py list
```

### Run Engineering Crew

```bash
python main.py engineering "Implement user authentication with OAuth2"
```

### Run Product Planning Crew

```bash
python main.py product "Add crop disease detection feature"
```

### Run ML Development Crew

```bash
python main.py ml "Train crop disease classification model"
```

### Run QA Testing Crew

```bash
python main.py qa "Test marketplace checkout flow"
```

### Run Executive Planning Crew

```bash
python main.py executive "Expand to 5 new states in India"
```

### Run Marketing Campaign Crew

```bash
python main.py marketing "Launch awareness campaign for monsoon season"
```

## Available Crews

| Crew | Description | Key Agents |
|------|-------------|------------|
| **EngineeringCrew** | Full-stack development | CTO, Tech Leads, Senior Developers, DevOps |
| **ProductCrew** | Product planning & design | CPO, Product Managers, UX Researchers, Designers |
| **MLCrew** | Machine learning development | Head of AI/ML, Senior ML Engineer, ML Developer |
| **QACrew** | Quality assurance & testing | Director of QA, QA Managers, QA Engineers |
| **ExecutiveCrew** | Strategic planning | CEO, CTO, CPO, CFO, CMO, COO, CISO |
| **MarketingCrew** | Marketing campaigns | CMO, Creative Director, Content & Social Directors |

## Programmatic Usage

```python
from crewai import LLM
from crewai_agents.agents.all_agents import create_cto, create_backend_tech_lead

# Use default LLM (based on environment variables)
cto = create_cto()

# Or specify a custom LLM
claude_llm = LLM(model="anthropic/claude-sonnet-4-20250514", api_key="your-key")
cto_with_claude = create_cto(llm=claude_llm)

openai_llm = LLM(model="openai/gpt-4o", api_key="your-key")
cto_with_openai = create_cto(llm=openai_llm)
```

## Regenerating Agents

If you update the `.claude/agents/` markdown files, regenerate the CrewAI agents:

```bash
python generate_agents.py
```

## Agent Count

- **Total Agents**: 112
- **Executive Team**: 14 (C-suite + VPs)
- **Engineering**: 30+ (Tech Leads, Developers, DevOps)
- **Product & Design**: 15+ (PMs, Designers, Researchers)
- **QA**: 8 (Director, Managers, Engineers)
- **Marketing & Community**: 15+ (Directors, Managers, Specialists)
- **ML/AI**: 3 (Head, Senior Engineer, Developer)

## Model Recommendations

| Use Case | Recommended Model |
|----------|-------------------|
| Complex reasoning, architecture | `claude-opus-4` or `gpt-4o` |
| General tasks, coding | `claude-sonnet-4-20250514` or `gpt-4-turbo` |
| Simple tasks, high volume | `claude-haiku` or `gpt-3.5-turbo` |
