from .base_agent import BaseAgent
from typing import List

def create_company_agents() -> List[BaseAgent]:
    agents = []

    # 1. C-Suite (5)
    c_suite = [
        BaseAgent("Alice", "CEO", "C-Suite"),
        BaseAgent("Bob", "CTO", "C-Suite", reports_to="CEO"),
        BaseAgent("Charlie", "CPO", "C-Suite", reports_to="CEO"),
        BaseAgent("Diana", "CFO", "C-Suite", reports_to="CEO"),
        BaseAgent("Edward", "COO", "C-Suite", reports_to="CEO"),
        BaseAgent("Fiona", "CMO", "C-Suite", reports_to="CEO"), # Chief Marketing Officer
    ]
    agents.extend(c_suite)

    # 2. VPs and Directors (5)
    leadership = [
        BaseAgent("Frank", "VP Engineering", "VP", reports_to="CTO"),
        BaseAgent("Grace", "VP Product", "VP", reports_to="CPO"),
        BaseAgent("Hank", "VP Design", "VP", reports_to="CPO"),
        BaseAgent("Ivy", "Director of Engineering", "Director", reports_to="VP Engineering"),
        BaseAgent("Jack", "Director of QA", "Director", reports_to="VP Engineering"),
        # Principal Engineers
        BaseAgent("Ken", "Principal Engineer (Backend)", "Principal", reports_to="VP Engineering"),
        BaseAgent("Leo", "Principal Engineer (Frontend)", "Principal", reports_to="VP Engineering"),
        # Custom Support Leadership
        BaseAgent("Zara", "VP Customer Success", "VP", reports_to="CEO"),
        # Security Leadership
        BaseAgent("Molly", "CISO", "C-Suite", reports_to="CEO"),
        BaseAgent("Olivia", "VP People", "VP", reports_to="CEO"),
        # Marketing Leadership
        BaseAgent("George", "VP Marketing", "VP", reports_to="CMO"),
        BaseAgent("Hannah", "Director of Content", "Director", reports_to="VP Marketing"),
        BaseAgent("Ian", "Director of Social", "Director", reports_to="VP Marketing"),
        BaseAgent("Jane", "Director of Community", "Director", reports_to="VP Marketing"),
        # Design Leadership
        BaseAgent("Kara", "Creative Director", "Director", reports_to="VP Design"),
        BaseAgent("Liam", "Head of Research", "Director", reports_to="VP Design"),
    ]
    agents.extend(leadership)

    # 3. Managers (6) -> Updated count
    managers = [
        # Engineering Managers
        BaseAgent("Kevin", "Engineering Manager (Backend)", "Manager", reports_to="Director of Engineering"),
        BaseAgent("Laura", "Engineering Manager (Frontend)", "Manager", reports_to="Director of Engineering"),
        BaseAgent("Mike", "Engineering Manager (Mobile)", "Manager", reports_to="Director of Engineering"),
        BaseAgent("Nina", "Manager - Database Engineering", "Manager", reports_to="Director of Engineering"), # New
        
        # Product Managers
        BaseAgent("Nancy", "Product Manager", "Manager", reports_to="VP Product"),
        BaseAgent("Oscar", "Design Lead", "Manager", reports_to="VP Design"),
        # Expanded Product Team
        BaseAgent("Peter", "Senior PM - Growth", "Manager", reports_to="VP Product"),
        BaseAgent("Quentin", "PM - Internal Tools", "Manager", reports_to="VP Product"),
        BaseAgent("Ruth", "PM - Data & ML", "Manager", reports_to="VP Product"),
        # Security Management
        BaseAgent("Seth", "Manager - Application Security", "Manager", reports_to="CISO"),
        # HR / Recruitment
        BaseAgent("Tara", "Recruiter", "IC", reports_to="VP People"),
        # Customer Support
        BaseAgent("Alan", "Support Lead", "Manager", reports_to="VP Customer Success"),
    ]
    agents.extend(managers)
    
    # 2.5 Program Management (TPMs)
    tpms = [
        BaseAgent("Sam", "Director of TPM", "Director", reports_to="VP Engineering"),
        BaseAgent("Tom", "TPM - Core Platform", "Manager", reports_to="Director of TPM"),
        BaseAgent("Uma", "TPM - Mobile Apps", "Manager", reports_to="Director of TPM"),
    ]
    agents.extend(tpms)

    # 2.6 Marketing & Community Teams (Massive Expansion)
    marketing_teams = [
        # Discord Team
        BaseAgent("Kevin_M", "Discord Manager", "Manager", reports_to="Director of Community"),
        BaseAgent("Liam_M", "Discord Mod (Support)", "IC", reports_to="Discord Manager"),
        BaseAgent("Mia_M", "Discord Mod (General)", "IC", reports_to="Discord Manager"),
        BaseAgent("Noah_M", "Event Coordinator", "IC", reports_to="Discord Manager"),
        
        # Twitch Team
        BaseAgent("Oliver_M", "Twitch Manager", "Manager", reports_to="Director of Community"),
        BaseAgent("Penny_M", "Stream Host (DevRel)", "IC", reports_to="Twitch Manager"),
        BaseAgent("Quinn_M", "Twitch Chat Mod", "IC", reports_to="Twitch Manager"),
        
        # Social Media Team
        BaseAgent("Riley_M", "Twitter Manager", "Manager", reports_to="Director of Social"),
        BaseAgent("Sarah_M", "LinkedIn Manager", "Manager", reports_to="Director of Social"),
        BaseAgent("Tim_M", "TikTok Specialist", "IC", reports_to="Director of Social"),
        
        # Content Team
        BaseAgent("Ursula_M", "Blog Editor", "IC", reports_to="Director of Content"),
        BaseAgent("Victor_M", "Video Producer", "IC", reports_to="Director of Content"),
    ]
    agents.extend(marketing_teams)

    # 4. ICs (15)
    ics = []
    
    # Backend Devs (3)
    ics.append(BaseAgent("Paul", "Backend Dev 1", "IC", reports_to="Engineering Manager (Backend)"))
    ics.append(BaseAgent("Quinn", "Backend Dev 2", "IC", reports_to="Engineering Manager (Backend)"))
    ics.append(BaseAgent("Rachel", "Backend Architect", "Architect", reports_to="Director of Engineering"))
    ics.append(BaseAgent("Tim", "Backend Dev 4", "IC", reports_to="Engineering Manager (Backend)"))
    ics.append(BaseAgent("Ugo", "Backend Dev 5", "IC", reports_to="Engineering Manager (Backend)"))

    # Frontend Devs (3)
    ics.append(BaseAgent("Steve", "Frontend Dev 1", "IC", reports_to="Engineering Manager (Frontend)"))
    ics.append(BaseAgent("Tina", "Frontend Dev 2", "IC", reports_to="Engineering Manager (Frontend)"))
    ics.append(BaseAgent("Ursula", "Frontend Architect", "Architect", reports_to="Director of Engineering"))

    # Mobile Devs (2)
    ics.append(BaseAgent("Victor", "Mobile Dev 1", "IC", reports_to="Engineering Manager (Mobile)"))
    ics.append(BaseAgent("Wendy", "Mobile Dev 2", "IC", reports_to="Engineering Manager (Mobile)"))

    # DevOps (2)
    ics.append(BaseAgent("Xander", "DevOps Engineer 1", "IC", reports_to="Director of Engineering"))
    ics.append(BaseAgent("Yara", "DevOps Engineer 2", "IC", reports_to="Director of Engineering"))

    # QA Leadership
    qa_managers = [
        BaseAgent("Viola", "Manager - QA", "Manager", reports_to="Director of QA"),
        BaseAgent("Wyatt", "Manager - Test Automation", "Manager", reports_to="Director of QA"),
        BaseAgent("Xena", "Manager - Performance Engineering", "Manager", reports_to="Director of QA"),
    ]
    agents.extend(qa_managers)

    # QA (3)
    ics.append(BaseAgent("Zach", "QA Engineer 1", "IC", reports_to="Manager - QA"))
    ics.append(BaseAgent("Amy", "QA Engineer 2", "IC", reports_to="Manager - QA"))
    ics.append(BaseAgent("Ben", "QA Engineer 3", "IC", reports_to="Manager - QA"))
    
    # Specialized QA ICs
    ics.append(BaseAgent("Cody", "Automation Engineer 1", "IC", reports_to="Manager - Test Automation"))
    ics.append(BaseAgent("Dana", "Performance Engineer 1", "IC", reports_to="Manager - Performance Engineering"))
    
    # Designers (Expanded)
    design_teams = [
        # Product Design
        BaseAgent("Cara", "Interaction Designer (IxD)", "IC", reports_to="Design Lead"),
        BaseAgent("Dan", "Visual Designer (UI)", "IC", reports_to="Design Lead"),
        BaseAgent("Ethan_D", "Design Systems Lead", "IC", reports_to="Design Lead"),
        
        # Creative Studio
        BaseAgent("Fiona_D", "Brand Designer", "IC", reports_to="Creative Director"),
        BaseAgent("Gavin_D", "Motion Designer", "IC", reports_to="Creative Director"),
        
        # Research
        BaseAgent("Hannah_R", "UX Researcher", "IC", reports_to="Head of Research"),
        BaseAgent("Ian_R", "UX Writer", "IC", reports_to="Design Lead"), # Or Head of Research, usually embeds in Product
    ]
    ics.extend(design_teams)

    # Security Engineers
    ics.append(BaseAgent("Evan", "Security Engineer 1", "IC", reports_to="Manager - Application Security"))
    ics.append(BaseAgent("Fay", "Security Engineer 2", "IC", reports_to="Manager - Application Security"))
    
    # Database Engineers
    ics.append(BaseAgent("Gus", "Senior DBA", "IC", reports_to="Manager - Database Engineering"))
    ics.append(BaseAgent("Hank2", "DB Reliability Engineer", "IC", reports_to="Manager - Database Engineering")) # Hank is taken, use Hank2 or logic

    # Customer Support Agent
    ics.append(BaseAgent("Beth", "Support Agent 1", "IC", reports_to="Support Lead"))

    agents.extend(ics)
    
    return agents
