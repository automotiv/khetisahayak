# Project Management with GitHub

## GitHub Projects Setup

### 1. Create a New Project
1. Go to your GitHub repository
2. Click on "Projects" tab
3. Click "New project"
4. Select "Board" template
5. Name it "Crop Health Diagnostics"
6. Click "Create"

### 2. Configure Project Settings
1. Click "..." in the top-right corner
2. Select "Manage"
3. Under "Workflow" select "Automated kanban with reviews"
4. Enable "Auto-close items"
5. Save changes

## Project Board Structure

### Columns
1. **Backlog** - Newly created issues
2. **To Do** - Ready for development
3. **In Progress** - Currently being worked on
4. **In Review** - Code review in progress
5. **Done** - Completed items

### Labels
Create the following labels:
- `feature/crop-health`
- `bug/crop-health`
- `enhancement/crop-health`
- `documentation`
- `priority/high`
- `priority/medium`
- `priority/low`

## Creating Issues from Tasks

### 1. Convert Tasks to Issues
For each task in `agile/crop_health_plan.md`, create a GitHub Issue:

```markdown
## [Task Name]

**Description:** [Brief description]

**Acceptance Criteria:**
- [ ] Criteria 1
- [ ] Criteria 2

**Technical Notes:**
- [Any technical considerations]

**Estimated Effort:** [S/M/L/XL]

**Dependencies:**
- [Related issue #]
```

### 2. Add to Project Board
1. When creating the issue, select the "Crop Health Diagnostics" project
2. Add appropriate labels
3. Set milestone if applicable
4. Assign to team member

## Workflow

### Development Workflow
1. Move issue to "In Progress" when starting work
2. Create a feature branch: `feature/crop-health/[issue-number]-short-description`
3. Make changes and commit with issue number: `git commit -m "#123 Add image capture functionality"`
4. Push changes and create a Pull Request
5. Move issue to "In Review"
6. After approval and merge, move to "Done"

### Weekly Sync
1. Review "In Progress" items
2. Update status of blocked items
3. Prioritize "To Do" items for next sprint
4. Review and close completed items

## GitHub Project Automation

### 1. Auto-add Issues
Create `.github/workflows/project-automation.yml`:

```yaml
name: Project Automation

on:
  issues:
    types: [opened, labeled]
  pull_request:
    types: [opened, closed]

jobs:
  add-to-project:
    runs-on: ubuntu-latest
    steps:
      - name: Add labeled issues to project
        if: github.event_name == 'issues' && contains(github.event.issue.labels.*.name, 'feature/crop-health')
        uses: actions/add-to-project@v0.3.0
        with:
          project-url: https://github.com/orgs/automotiv/projects/[PROJECT_NUMBER]
          github-token: ${{ secrets.GITHUB_TOKEN }}
          labeled: 'feature/crop-health'
          column-name: 'To do'
```

### 2. Auto-close Issues
Add to the same workflow:

```yaml
  close-issues:
    runs-on: ubuntu-latest
    steps:
      - name: Close issues when PR is merged
        if: github.event_name == 'pull_request' && github.event.pull_request.merged == true
        uses: actions/github-script@v5
        with:
          script: |
            const issueNumber = context.issue.number;
            await github.rest.issues.update({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: issueNumber,
              state: 'closed'
            });
```

## Reporting

### Burndown Chart
1. Go to Project board
2. Click on "Insights"
3. View "Burndown" chart for progress tracking

### Velocity Tracking
1. Under "Insights"
2. View "Velocity" to track completed work across sprints

## Best Practices
1. Keep issues small and focused
2. Update status regularly
3. Use labels consistently
4. Link related issues
5. Include acceptance criteria in every issue

## Integration with Other Tools

### 1. Slack Notifications
Set up GitHub-Slack integration to get updates:
1. Go to Slack App Directory
2. Add GitHub integration
3. Configure notifications for:
   - New issues
   - PR updates
   - Project board changes

### 2. CI/CD Pipeline
Add status checks to PRs:
1. Linting
2. Unit tests
3. Integration tests
4. Build verification

## Resources
- [GitHub Projects Documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [Project Automation](https://github.com/features/actions)
- [Project Templates](https://github.com/features/project-management/)
