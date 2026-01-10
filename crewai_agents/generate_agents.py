#!/usr/bin/env python3
"""
Script to parse Claude agent markdown files and generate CrewAI agent definitions.
"""

import os
import re
import yaml
from pathlib import Path


def parse_agent_markdown(file_path: str) -> dict:
    """Parse a Claude agent markdown file and extract metadata."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract YAML frontmatter
    frontmatter_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not frontmatter_match:
        return None
    
    frontmatter = yaml.safe_load(frontmatter_match.group(1))
    
    # Extract the rest of the content (backstory)
    body = content[frontmatter_match.end():].strip()
    
    # Extract the title (first # heading)
    title_match = re.search(r'^#\s+(.+)$', body, re.MULTILINE)
    title = title_match.group(1) if title_match else os.path.basename(file_path).replace('.md', '').replace('-', ' ').title()
    
    # Get the agent name from filename
    agent_name = os.path.basename(file_path).replace('.md', '')
    
    return {
        'name': agent_name,
        'title': title,
        'description': frontmatter.get('description', ''),
        'model': frontmatter.get('model', 'anthropic/claude-sonnet-4-5'),
        'temperature': frontmatter.get('temperature', 0.3),
        'backstory': body
    }


def generate_crewai_agent_code(agent_data: dict) -> str:
    """Generate CrewAI agent Python code from parsed data."""
    # Convert agent name to valid Python identifier
    func_name = agent_data['name'].replace('-', '_')
    
    # Extract role from title or description
    role = agent_data['title']
    
    # Extract goal from description
    goal = agent_data['description']
    
    backstory = agent_data['backstory'][:2000]
    backstory = backstory.replace('\\', '\\\\')
    backstory = backstory.replace('"', '\\"')
    backstory = backstory.replace('\n', '\\n')
    backstory = backstory.replace('\r', '')
    
    role = role.replace('"', '\\"')
    goal = goal.replace('"', '\\"')
    
    return f'''
def create_{func_name}(llm=None) -> Agent:
    return Agent(
        role="{role}",
        goal="{goal}",
        backstory="{backstory}",
        llm=llm or _get_llm(),
        verbose=True,
        allow_delegation=True
    )
'''


def main():
    agents_dir = Path(__file__).parent.parent / '.claude' / 'agents'
    output_file = Path(__file__).parent / 'agents' / 'all_agents.py'
    
    # Parse all agent files
    agents = []
    for md_file in sorted(agents_dir.glob('*.md')):
        agent_data = parse_agent_markdown(str(md_file))
        if agent_data:
            agents.append(agent_data)
            print(f"Parsed: {agent_data['name']}")
    
    print(f"\nTotal agents parsed: {len(agents)}")
    
    code = '''"""
CrewAI Agent Definitions for Kheti Sahayak
Auto-generated from .claude/agents/ markdown files

Supports both OpenAI and Anthropic (Claude) models.
Set LLM via environment variable or pass to agent creation functions.
"""

import os
from crewai import Agent, LLM


def get_default_llm() -> LLM:
    """Get the default LLM based on environment configuration."""
    provider = os.getenv("CREWAI_LLM_PROVIDER", "anthropic").lower()
    
    if provider == "anthropic":
        model = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514")
        return LLM(
            model=f"anthropic/{model}",
            api_key=os.getenv("ANTHROPIC_API_KEY")
        )
    elif provider == "openai":
        model = os.getenv("OPENAI_MODEL", "gpt-4o")
        return LLM(
            model=f"openai/{model}",
            api_key=os.getenv("OPENAI_API_KEY")
        )
    else:
        raise ValueError(f"Unsupported LLM provider: {provider}")


DEFAULT_LLM = None


def _get_llm():
    global DEFAULT_LLM
    if DEFAULT_LLM is None:
        DEFAULT_LLM = get_default_llm()
    return DEFAULT_LLM


'''
    
    for agent in agents:
        code += generate_crewai_agent_code(agent)
        code += '\n'
    
    # Add a function to get all agents
    code += '''
def get_all_agents() -> list[Agent]:
    """Return a list of all available agents."""
    return [
'''
    for agent in agents:
        func_name = agent['name'].replace('-', '_')
        code += f'        create_{func_name}(),\n'
    code += '''    ]


def get_agent_by_name(name: str) -> Agent:
    """Get a specific agent by name."""
    agent_map = {
'''
    for agent in agents:
        func_name = agent['name'].replace('-', '_')
        code += f'        "{agent["name"]}": create_{func_name},\n'
    code += '''    }
    if name not in agent_map:
        raise ValueError(f"Unknown agent: {name}")
    return agent_map[name]()
'''
    
    # Write the output file
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(code)
    
    print(f"\nGenerated: {output_file}")


if __name__ == '__main__':
    main()
