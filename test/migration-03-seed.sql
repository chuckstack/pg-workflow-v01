set search_path = 'private';
select stack_wf_template_process_create_approval_traditional(true,'Employee Leave') as process_uu;
select 'process' as coming_next;
select * from stack_wf_process;
select 'state' as coming_next;
select * from stack_wf_state;
select 'action' as coming_next;
select * from stack_wf_action;
select 'resolution' as coming_next;
select * from stack_wf_resolution;
select 'target' as coming_next;
select * from stack_wf_target;
select 'group' as coming_next;
select * from stack_wf_group;
select 'transition' as coming_next;
select * from stack_wf_transition;
select 'action transition link' as coming_next;
select * from stack_wf_action_transition_lnk;
