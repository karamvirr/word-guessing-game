import consumer from "channels/consumer"

(() => {
  const split = window.location.pathname.split('/');
  if (split[1] === 'staging_area' && typeof split[2] === 'string') {
    const slug = split[2];
    const channel = consumer.subscriptions.create({ channel: 'StagingAreaChannel', slug: slug }, {
      // Called when the subscription is ready for use on the server
      connected() {
        console.log('connected to staging area channel!');
      },

      // Called when the subscription has been terminated by the server
      disconnected() {
        console.log('disconnected from staging area channel!');
      },

      // Called when there's incoming data on the websocket for this channel
      received(data) {
        const range = document.createRange();
        let players = [];
        if (data.users.length > 0) {
          document.querySelector('#room-information').classList.remove('hidden');
          data.users.forEach((user) => {
            let playerCardHTML = `
              <div class="c-card animate-pop-in">
                <p>${user.name}</p>
              </div>
            `;
            const playerCard = range.createContextualFragment(playerCardHTML);
            players.push(playerCard);
          });
          document.querySelector('.player-staging-container').replaceChildren(...players);
        } else {
          document.querySelector('#room-information').classList.add('hidden');
        }
      },
    });

    const nameInput = document.querySelector('#name_input');
    const submitButton = document.querySelector('form > button');

    const names = () => {
      return Array.from(
        document.querySelectorAll('.c-card > p')
      ).map((node) => { return node.innerText; });
    }

    const shake = () => {
      const form = document.querySelector('form');

      form.classList.add('invalid-input');
      setTimeout(() => {
        form.classList.remove('invalid-input');
      }, 500);
    }

    const setNameRequest = (name) => {
      name = name.trim();
      if (names().includes(name)) {
        document.querySelector('p.error').innerText = `'${name}' is already taken, please enter another.`;
        shake();
        return;
      }
      console.log('here...');
      // Calls 'StagingAreaChannel#set_name(data)' on the server.
      channel.perform('set_name', { name: name });
      // Now that our name is set, let's hop into the game room! :)
      window.location.href = `/room/${slug}`;
    };

    submitButton.addEventListener('click', (event) => {
      event.preventDefault();
      if (nameInput.value.length > 0) {
        setNameRequest(nameInput.value);
      }
    });
    nameInput.addEventListener('keydown', (event) => {
      if (event.code === 'Enter') {
        event.preventDefault();
        if (event.target.value.length > 0) {
          setNameRequest(event.target.value);
        }
      }
    })
  }
})();
