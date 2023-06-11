import consumer from "channels/consumer"

(() => {
  const split = window.location.pathname.split('/');
  if (split[1] === 'staging_areas' && typeof split[2] === 'string') {
    const slug = split[2];
    const channel = consumer.subscriptions.create({ channel: 'StagingAreaChannel', slug: slug }, {
      // Called when the subscription is ready for use on the server
      connected() {
        console.log('staging_area - connected');
      },

      // Called when the subscription has been terminated by the server
      disconnected() {
        console.log('staging_area - disconnected');
      },

      // Called when there's incoming data on the websocket for this channel
      received(data) {
        switch (data.context) {
          case 'refresh_players':
            this.refreshPlayers(data.payload);
            break;
          case 'usher_to_game_room':
            this.redirectToGameRoom(data);
            break;
        }
      },

      refreshPlayers(data) {
        const range = document.createRange();
        let players = [];
        document.querySelector('h3').innerText = `Players in room '${data.slug}' (${data.users.length})`
        if (data.users.length > 0) {
          document.querySelector('#room-information').classList.remove('hidden');
          data.users.forEach((user) => {
            let playerCardHTML = `
              <div class="c-card animate-pop-in">
                <p class="title">${user.name}</p>
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

      redirectToGameRoom(data) {
        window.location.href = `/rooms/${data.slug}`;
      }
    });

    const nameInput = document.querySelector('#name_input');
    const submitButton = document.querySelector('form > button');

    const names = () => {
      return Array.from(
        document.querySelectorAll('.c-card > .title')
      ).map((node) => { return node.innerText; });
    }

    const sanitizeInput = (input) => {
      if (input) {
        return input.replace(/<(.|\n)*?>/g, '').trim();
      }
      return "";
    };

    const shake = () => {
      const form = document.querySelector('form');

      form.classList.add('invalid-input');
      setTimeout(() => {
        form.classList.remove('invalid-input');
      }, 500);
    }

    const setNameRequest = (name) => {
      if (names().includes(name) || name.length === 0) {
        if (name.length === 0) {
          document.querySelector('p.error').innerText = `Please enter a name.`;
        } else {
          document.querySelector('p.error').innerText = `
            '${name}' is already taken, please enter another.
          `;
        }
        shake();
        return;
      }
      // Calls 'StagingAreaChannel#set_name(data)' on the server.
      channel.perform('set_name', { name: name });
    };

    submitButton.addEventListener('click', (event) => {
      event.preventDefault();
      setNameRequest(sanitizeInput(nameInput.value));
    });
    nameInput.addEventListener('keydown', (event) => {
      if (event.code === 'Enter') {
        event.preventDefault();
        setNameRequest(sanitizeInput(event.target.value));
      }
    });
  }
})();
