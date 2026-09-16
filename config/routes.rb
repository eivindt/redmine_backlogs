def rb_match(path, hash)
  if not hash[:via]
    hash[:via] = [:get]
  end
  match path, **hash
end

scope 'rb' do
  rb_match 'releases/:project_id',
               :to => 'rb_releases#index', :via => [:get]
  rb_match 'release/:project_id/new', :to => 'rb_releases#new', :via => [:get]
  rb_match 'release/:project_id/new', :to => 'rb_releases#create', :via => [:post]
  rb_match 'release/:release_id',
               :to => 'rb_releases#show', :via => [:get]
  rb_match 'release/:release_id',
               :to => 'rb_releases#destroy', :via => [:delete]
  rb_match 'release/:release_id/edit',
               :to => 'rb_releases#edit', :via => [:get, :post]
  rb_match 'release/:release_id/update',
               :to => 'rb_releases#update', :via => [:put]
  rb_match 'release/:release_id/shapshot',
               :to => 'rb_releases#snapshot', :via => [:get]

  rb_match 'releases_multiview/:project_id/new',
               :to => 'rb_releases_multiview#new', :via => [:get, :post]
  rb_match 'releases_multiview/:release_multiview_id',
               :to => 'rb_releases_multiview#show', :via => [:get]
  rb_match 'releases_multiview/:release_multiview_id',
               :to => 'rb_releases_multiview#destroy', :via => [:delete]
  rb_match 'releases_multiview/:release_multiview_id/edit',
               :to => 'rb_releases_multiview#edit', :via => [:get, :post]

  rb_match 'updated_items/:project_id', :to => 'rb_updated_items#show', :via => [:get]
  rb_match 'wikis/:sprint_id', :to => 'rb_wikis#show', :via => [:get]
  rb_match 'wikis/:sprint_id/edit', :to => 'rb_wikis#edit', :via => [:get]
  rb_match 'issues/backlog/product/:project_id',
               :to => 'rb_queries#show', :via => [:get]
  rb_match 'issues/backlog/sprint/:sprint_id',
               :to => 'rb_queries#show', :via => [:get]
  rb_match 'issues/impediments/sprint/:sprint_id',
               :to => 'rb_queries#impediments', :via => [:get]
  rb_match 'statistics', :to => 'rb_all_projects#statistics', :via => [:get]

  rb_match 'server_variables/sprint/:sprint_id.js',
              :to => 'rb_server_variables#sprint',
              :format => 'js', :via => [:get]
  rb_match 'server_variables/sprint/:sprint_id.js',
              :to => 'rb_server_variables#sprint',
              :format => nil, :via => [:get]
  rb_match 'server_variables.js',
              :to => 'rb_server_variables#index',
              :via => [:get],
              :format => 'js'
  rb_match 'server_variables.js',
              :to => 'rb_server_variables#index',
              :format => nil, :via => [:get]
  rb_match 'server_variables/project/:project_id.js',
              :to => 'rb_server_variables#project',
              :format => 'js', :via => [:get]
  rb_match 'server_variables/project/:project_id.js',
              :to => 'rb_server_variables#project',
              :format => nil, :via => [:get]

  rb_match 'master_backlog/:project_id',
               :to => 'rb_master_backlogs#show', :via => [:get]
  rb_match 'master_backlog/:project_id/menu',
               :to => 'rb_master_backlogs#menu', :via => [:get]
  rb_match 'master_backlog/:project_id/closed_sprints', :to => 'rb_master_backlogs#closed_sprints', :via => [:get]

  rb_match 'impediment/create', :to => 'rb_impediments#create', :via => [:post]
  rb_match 'impediment/update/:id', :to => 'rb_impediments#update', :via => [:post, :put]

  rb_match 'sprint/create', :to => 'rb_sprints#create', :via => [:post]
  rb_match 'sprint/:sprint_id/update', :to => 'rb_sprints#update', :via => [:post, :put]
  rb_match 'sprint/:sprint_id/close', :to => 'rb_sprints#close', :via => [:get, :post, :put]
  rb_match 'sprint/:sprint_id/reset', :to => 'rb_sprints#reset', :via => [:post, :put, :get]
  rb_match 'sprint/download/:sprint_id.xml', :to => 'rb_sprints#download', :format => 'xml', :via => [:get]
  rb_match 'sprints/:project_id/close_completed', :to => 'rb_sprints#close_completed', :via => [:put]

  rb_match 'stories/:project_id/:sprint_id.pdf', :to => 'rb_stories#index', :format => 'pdf', :via => [:get]
  rb_match 'stories/:project_id.pdf', :to => 'rb_stories#index', :format => 'pdf', :via => [:get]
  rb_match 'story/create', :to => 'rb_stories#create', :via => [:post, :put]
  rb_match 'story/update/:id', :to => 'rb_stories#update', :via => [:post, :put]
  rb_match 'story/:id/tooltip', :to => 'rb_stories#tooltip', :via => [:get]

  rb_match 'calendar/:key/:project_id.ics', :to => 'rb_calendars#ical',
          :format => 'xml', :via => [:get]

  rb_match 'burndown/:sprint_id',         :to => 'rb_burndown_charts#show', :via => [:get]
  rb_match 'burndown/:sprint_id/embed',   :to => 'rb_burndown_charts#embedded', :via => [:get]
  rb_match 'burndown/:sprint_id/print',   :to => 'rb_burndown_charts#print', :via => [:get]

  rb_match 'hooks/sidebar/project/:project_id',
          :to => 'rb_hooks_render#view_issues_sidebar', :via => [:get]
  rb_match 'hooks/sidebar/project/:project_id/:sprint_id',
          :to => 'rb_hooks_render#view_issues_sidebar', :via => [:get]

  rb_match 'project/:project_id/backlogs', :to => 'rb_project_settings#project_settings', :via => [:get, :post]

  resources :task, :except => :index, :controller => :rb_tasks
  rb_match 'tasks/:story_id', :to => 'rb_tasks#index', :via => [:get]

  rb_match 'taskboards/:sprint_id',
            :to => 'rb_taskboards#show', :via => [:get]
  rb_match 'projects/:project_id/taskboard',
            :to => 'rb_taskboards#current', :via => [:get]
end
