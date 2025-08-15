import os
import re
import subprocess

def create_issue(title, body):
    """Creates a GitHub issue."""
    subprocess.run(
        [
            "gh",
            "issue",
            "create",
            "--title",
            title,
            "--body",
            body,
            "--project",
            "Kheti Sahayak MVP",
        ],
        check=True,
    )

def main():
    """Parses the agile plan and creates GitHub issues."""
    with open("khetisahayak.wiki/agile/crop_health_plan.md", "r") as f:
        content = f.read()

    # Split content by features
    features = content.split("### ")
    
    for feature_block in features[1:]: # Skip the epic intro
        lines = feature_block.strip().split('\n')
        feature_title = lines[0].strip()
        
        # Create a main issue for the feature itself
        user_story = re.search(r"\*\*User Story\*\*:\s(.*?)$", feature_block, re.MULTILINE)
        feature_body = user_story.group(1) if user_story else "Plan and implement feature."
        create_issue(f"Feature: {feature_title}", feature_body)

        # Find and create issues for each task in the feature
        tasks = re.findall(r"-\s\[\s\]\s(.*?)$", feature_block, re.MULTILINE)
        for task in tasks:
            task_title = task.strip()
            issue_title = f"Task [{feature_title}]: {task_title}"
            issue_body = f"Part of the **{feature_title}** feature.\n\n**Objective:** {task_title}"
            create_issue(issue_title, issue_body)

if __name__ == "__main__":
    main()
