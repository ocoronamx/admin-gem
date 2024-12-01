module ApplicationHelper
  def inbox
    @inbox ||= [ { sender: 'Brad Diesel', avatar_path: 'dist/img/user1-128x128.jpg', message: 'Call me whenever you can...', time: '4 Hours', status_class: 'text-danger' },
      { sender: 'Brad Diesel', avatar_path: 'dist/img/user1-128x128.jpg', message: 'I got your message bro', time: '4 Hours', status_class: 'text-muted' },
      { sender: 'Nora Silvester', avatar_path: 'dist/img/user3-128x128.jpg', message: 'The subject goes here', time: '6 Hours', status_class: 'text-warning' } ]
  end
  def notifications
    @notifications ||= [
      { title: 'friend requests', amount: 4, time: '12 hours', icon_class: 'fas fa-users', path: '#' },
      { title: 'new reports', amount: 3, time: '8 hours', icon_class: 'fas fa-file', path: '#' }
    ]
  end
end
